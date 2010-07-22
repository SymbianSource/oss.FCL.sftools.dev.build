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

import java.io.File;
import java.util.List;
import java.util.Map;
import java.util.ArrayList;
import fmpp.Engine;
import fmpp.ProgressListener;
import fmpp.tdd.DataLoader;
import freemarker.template.TemplateCollectionModel;
import freemarker.template.TemplateModel;
import freemarker.template.TemplateHashModel;
import freemarker.template.TemplateSequenceModel;
import freemarker.template.SimpleScalar;
import freemarker.template.SimpleNumber;
import freemarker.template.TemplateModelIterator;
import com.nokia.helium.jpa.ORMReader;
import org.apache.log4j.Logger;
import freemarker.ext.beans.BeanModel;
import freemarker.ext.beans.BeansWrapper;



/**
 * Utility class to access the data from the database and used by FMPP
 * templates.
 */
public class ORMFMPPLoader implements DataLoader {
    //private ResultSet rs;
    private static final int READ_LIMIT = 20000;

    private static Logger log = Logger.getLogger(ORMFMPPLoader.class);

    private ORMReader reader;


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
        ORMQueryModeModel model = new ORMQueryModeModel((String) (args.get(0)));
        engine.setAttribute(this.getClass().toString(), model);
        return model;
    }

    /**
     * QueryModel (which supports hash, sequence, containers)
     * arg[0] - dbpath
     *  
     */
    private class ORMQueryModeModel implements TemplateHashModel, ProgressListener {

        private String dbPath;
        public ORMQueryModeModel(String path) {
            File actualPath = new File(path);
            String fileName = actualPath.getName();
            dbPath = new File(actualPath.getParent(), fileName.toLowerCase()).getPath();
        }
        
        /*
         * Gets the template model for the corresponding query
         * @param query for which the model is returned.
         * @return returns the template model for the query 
         */
        public QueryTemplateModel get(String mode) {
            String retType = null;
            String actualMode = mode;
            //log.debug("mode: " + mode);
            if (mode.startsWith("native")) {
                String [] splitString = mode.split(":");
                if (splitString.length == 2 ) {
                    actualMode = splitString[0]; 
                    retType = splitString[1];
                    //log.debug("actualMode " + actualMode);
                    //log.debug("retType " + retType);
                }
            }
            
            return new QueryTemplateModel(dbPath, actualMode, retType);
        }
        
        public boolean isEmpty() {
            return false;
        }

        /**
         * {@inheritDoc}
         */
        @Override
        public void notifyProgressEvent(Engine engine, int event, File src,
                int pMode, Throwable error, Object param) throws Exception {
            //if (event == ProgressListener.EVENT_END_PROCESSING_SESSION) {
            //    log.debug("notifyProgressEvent - finalizeORM");
            //    ORMUtil.finalizeORM(dbPath);
            //}  
         }
    }

    /*
     * Internal class to handle the sql query and returns the data in either
     * hash or sequence or containers.
     */
    private class QueryTemplateModel implements TemplateHashModel {

        private String dbPath;
        
        private String queryMode;
        
        private String returnType;
        
        private TemplateModel resultObject;
        
        public QueryTemplateModel(String path, String mode, String retType) {
            dbPath = path;
            queryMode = mode;
            returnType = retType;
        }

        public TemplateModel get(String query) {
            //log.debug("QueryTemplateModel: query" + query);
            if (queryMode.equals("jpasingle")) {
                //log.debug("query executing with single result mode");
                resultObject = getModel(dbPath, query, returnType);
                
            } else {
                //log.debug("query executing with multiple result mode");
                resultObject = new ORMQueryModel(dbPath, query, queryMode, returnType); 
            }
            return resultObject;
        }
        
        private TemplateModel getModel(String dbPath, String query, 
                String returnType) {
            ORMReader reader = new ORMReader(dbPath);
            ORMSequenceModel model = new ORMSequenceModel(reader.executeSingleResult(query, returnType));
            reader.close();
            return model;
        }

        public boolean isEmpty() {
            //log.debug("query hash isempty:");
            return false;
        }
    }
    
    private class ORMSequenceModel implements TemplateSequenceModel {
        private List ormList = new ArrayList();

        @SuppressWarnings("unchecked")
        public ORMSequenceModel(Object obj) {
            ormList.add(obj);
        }
        public int size() {
            return ormList.size();
        }

        public TemplateModel get(int index) {
            //log.debug("ORMSequenceModel.get: index: " + index);
            if (index < ormList.size()) {
                Object obj = ormList.get(index);
                if (obj instanceof String) {
                    return new SimpleScalar((String)obj);
                } else if (obj instanceof Number) {
                    return new SimpleNumber((Number)obj);
                } else if (obj == null) {
                    return null;
                } else {
                    return new ORMObjectModel(obj);
                }
            }
            return null;
        }
    }
    
    private class ORMQueryModel implements TemplateCollectionModel 
         {
        
        private ORMReader ormReader;
        private String queryType;
        private String query;
        private String returnType;

        public ORMQueryModel (String dbPath, String queryString, String type, String retType) {
            ormReader = new ORMReader(dbPath);
            queryType = type;
            query = queryString;
            returnType = retType;
            //log.debug("ORMQueryModel: query" + query);
        }
        
        /*
         * Provides data via collection interface.
         * @return the iterator model from which the data is accessed.
         */
        public TemplateModelIterator iterator() {
            //log.debug("iterator constructor called");
            return new ORMTemplateModelIterator(ormReader, query, queryType, returnType);
        }
        
    }

    /*
     * Internal Iterator class which provides data as collection. 
     */
    private class ORMTemplateModelIterator implements TemplateModelIterator {
        
        private String query;
        private List<Map<String, Object>> rowList;
        private int currentOffsetIndex;
        private boolean finished;
        private String returnType;
        private boolean nativeQuery;
        private ORMReader ormReader;
        
        public ORMTemplateModelIterator(ORMReader reader, String queryString, String type, String retType) {
            ormReader = reader;
            query = queryString;
            returnType = retType;
            if (type.startsWith("native")) {
                nativeQuery = true;
            }
            //log.debug("ORMTemplateModelIterator: query" + query);
        }

        /**
         * {@inheritDoc}
         */
        @SuppressWarnings("unchecked")
        public TemplateModel next() {
            //log.debug("ORMTemplateModelIterator: next");
            Object toRet = null;
                if (rowList != null) {
                    toRet = rowList.remove(0);
                }
                if (nativeQuery && returnType.equals("java.lang.String")) {
                    return new SimpleScalar((java.lang.String)toRet);
                }
                return new ORMObjectModel(toRet);
        }
        
        /**
         * {@inheritDoc}
         */
        @SuppressWarnings("unchecked")
        public boolean hasNext() {
            if (rowList == null  || rowList.size() == 0) {
                if (!finished) {
                    if (nativeQuery) {
                        if (returnType.equals("java.lang.String")) {
                            rowList = ormReader.executeNativeQuery(query, null);
                        } else {
                            rowList = ormReader.executeNativeQuery(query, returnType);
                        }
                    } else {
                        rowList = ormReader.executeQuery(query);
                    }
                    if (rowList == null || rowList.size() == 0) {
                        finished = true;
                        ormReader.close();
                    }
                }
            }
            return !finished;
        }
    }
    
    private class ORMObjectModel extends BeanModel {
        public ORMObjectModel(Object obj) {
            super(obj, new BeansWrapper());
        }
    }
}