/*
 * Copyright (c) 2007-2008 Nokia Corporation and/or its subsidiary(-ies).
 * All rights reserved.
 * This component and the accompanying materials are made available
 * under the terms of the License "Eclipse Public License v1.0"
 * which accompanies this distribution, and is available
 * at the URL "http://www.eclipse.org/legal/epl-v10.html".
 *
 * Initial Contributors:
 * Nokia Corporation - initial contribution.
 *
 * Contributors:
 *
 * Description:  
 *
 */
package com.nokia.helium.metadata;

import java.util.List;
import java.util.Map;

import fmpp.Engine;
import fmpp.tdd.DataLoader;
import freemarker.template.TemplateCollectionModel;
import freemarker.template.TemplateModel;
import freemarker.template.TemplateHashModel;
import freemarker.template.TemplateSequenceModel;
import freemarker.template.TemplateHashModelEx;
import freemarker.template.SimpleHash;
import freemarker.template.SimpleCollection;
import freemarker.template.SimpleSequence;
import freemarker.template.SimpleScalar;
import freemarker.template.TemplateModelIterator;
import com.nokia.helium.metadata.db.MetaDataDb;
import org.apache.log4j.Logger;


/**
 * Utility class to access the data from the database and used by FMPP
 * templates.
 */ 
public class SQLFMPPLoader implements DataLoader {
    
    //private ResultSet rs;
    private static final int READ_LIMIT = 5000;

    private static Logger log = Logger.getLogger(MetaDataDb.class);

    private MetaDataDb metadataDb;


    /**
     * @see fmpp.tdd.DataLoader#load(fmpp.Engine, java.util.List)
     */
    public Object load(Engine engine, List args) throws Exception {
        //log.debug("args.size:" + args.size());
        java.util.ListIterator iter = args.listIterator();
        int argsSize = args.size();
        if (argsSize < 1) {
            throw new Exception("Input DB path should be provided to load into FMPP.");
        }

        /* arg[0] - dbpath
         */
        metadataDb = new MetaDataDb((String) (args.get(0)));
        
        /*
         * QueryModel (which supports hash, sequence, containers)
         *  
         */
        return new QueryModel();
    }

    /*
     * Internal class to handle the sql query and returns the data in either
     * hash or sequence or containers.
     */
    private class QueryModel implements TemplateHashModel {

        /*
         * Gets the template model for the corresponding query
         * @param query for which the model is returned.
         * @return returns the template model for the query 
         */
        public TemplateModel get(String query) {
            //log.debug("QueryModel:" + query);
            return new QueryTemplateModel(query);
        }

        /*
         * This model will not be empty as new object is returned. So false is returned.
         */
        public boolean isEmpty() {
            return false;
        }
    }

    /*
     * Template model makes request to metadata db class to get the data and present it
     * based on hash, sequence or containers.
     * Todo: avoid the calling of checkAndReadData for each of the function.
     */    
    private class QueryTemplateModel implements TemplateCollectionModel, TemplateHashModelEx,
        TemplateSequenceModel {
        
        private Map<String, List<String>> indexMap;
        private String query;
        private boolean isDataRead;

        /*
         * Constructor for the query model
         * @param query for which the template model needs to be returned.
         */
        public QueryTemplateModel(String query) {
            //log.debug("query in SQLTemplateModel" + query);
            this.query = query;
        }

        /*
         * HashModel interface. When the template requests as hash then 
         * @param query for which the template model needs to be returned.
         */
        public TemplateModel get(String key) {
            checkAndReadData();
            //log.debug("QueryModel:" + key);
            List<String> dataList = indexMap.get(key);
            //log.debug("datalist size" + dataList.size());
            if (dataList.size() ==  1 ) {
                return new SimpleScalar((String)dataList.get(0));
            }
            return new SimpleSequence(dataList);
        }

        /*
         * Read the data from database if it is not done already. Used
         * by hash and sequence model only. 
         */
        private void checkAndReadData() {
            if (!isDataRead) {
                //log.debug("isDataRead:" + isDataRead);
                isDataRead = true;
                indexMap = metadataDb.getIndexMap(query); 
            }
            //log.debug("indexmap size" + indexMap.size());
        }

        /*
         * HashModel interface. When the template requests as hash then 
         * data is read from memory and the keys are returned.
         * @return the keys of the primary key data (currently column 1) 
         * read from db
         */
        public TemplateCollectionModel keys() {
            checkAndReadData();
            return new SimpleCollection(indexMap.keySet());
        }

        /*
         * Return the size of the records read from db
         * @return the size of the db records.
         */
        public int size() {
            checkAndReadData();
            return indexMap.size();
            
        }

        /*
         * Gets the record on a particular index
         * @return the record as hash model.
         */
        public TemplateModel get(int index) {
            List<Map<String, Object>> rowList = metadataDb.getRecords(query);
            return new SimpleHash(rowList.get(index));
        }

        /*
         * Gets the record on a particular index
         * @return the record as hash model.
         */
        public boolean isEmpty() {
            checkAndReadData();
            return indexMap == null;
        }

        /*
         * Gets the record on a particular index
         * @return the record as hash model.
         */
        public TemplateCollectionModel values() {
            checkAndReadData();
            return new SimpleCollection(indexMap.values());
        }

        /*
         * Provides data via collection interface.
         * @return the iterator model from which the data is accessed.
         */
        public TemplateModelIterator iterator() {
            //log.debug("iterator constructor called");
            return new SQLTemplateModelIterator(query);
        }
    }

    /*
     * Internal Iterator class which provides data as collection. 
     */
    private class SQLTemplateModelIterator implements TemplateModelIterator {
        
        private String query;
        private List<Map<String, Object>> rowList;
        private int currentOffsetIndex;
        private int count;
        private boolean finished;
        
        public SQLTemplateModelIterator(String query) {
            this.query = query;
        }
        public TemplateModel next() {
            SimpleHash simpleHash = null;
            try {
                //log.debug("checking any more element");
                if (rowList != null && (count >= rowList.size())) {
                    finished = true;
                }
                //log.debug("next:count:" + count);
                simpleHash = new SimpleHash(rowList.get(count));
                count ++;
                return simpleHash;
            } catch (Exception ex) {
                // We are Ignoring the errors as no need to fail the build.
                log.debug("Iteration exception", ex);
            }
            return null;
        }

        public boolean hasNext() {
            if (rowList == null ||  READ_LIMIT <= count) {
                if (!finished) {
                    //log.debug("Getting records");
                    rowList = metadataDb.getRecords(query, READ_LIMIT, currentOffsetIndex * READ_LIMIT);
                    count = 0;
                    //log.debug("rowList.size : " + rowList.size());
                    if (rowList.size() == 0) {
                        finished = true;
                    }
                    currentOffsetIndex ++;
                }
            }
            int rowListSize = rowList.size(); 
            if (rowListSize < READ_LIMIT && rowListSize == count) {
                finished = true;
            }
            return !finished;
        }
    }
}