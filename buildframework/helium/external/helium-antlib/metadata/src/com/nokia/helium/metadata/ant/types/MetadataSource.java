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

package com.nokia.helium.metadata.ant.types;

import com.nokia.helium.core.LogSource;
import com.nokia.helium.metadata.db.MetaDataDb;
import org.apache.log4j.Logger;
import java.io.File;
import java.util.List;
import java.util.Map;
import java.io.BufferedWriter;
import java.io.FileWriter;

/**
 * This type define an input source that will be communicated to the notifiers.
 * Not used, deprecated and an xml and html file is generated for signal modules.
 * @ant.type name="metadatasource" category="Metadata"
 * @deprecated
 * 
 */
public class MetadataSource extends LogSource {

    private static Logger logger = Logger.getLogger(MetadataSource.class);

    private String db;
    private String log;
    
    public void setDb(String db) {
        this.db = db;
    }
    
    public String getDb() {
        return db;
    }
    
    public void setLog(String log) {
        this.log = log;
    }
    
    public String getLog() {
        return log;
    }
    
    public File getFilename()
    {
        MetaDataDb mdb = new MetaDataDb(db);

        String sql = "select * from metadata INNER JOIN logfiles ON logfiles.id=metadata.logpath_id INNER JOIN priority ON priority.id=metadata.priority_id where priority='ERROR' and path like '%" + log + "'";
        
        List<Map<String, Object>> records = mdb.getRecords(sql);
        
        try {
            File temp = File.createTempFile("templog.", ".xml");
            temp.deleteOnExit();
            BufferedWriter output = new BufferedWriter(new FileWriter(temp));
            output.write("<?xml version=\"1.0\" encoding=\"utf-8\"?>\n<log filename=\"" + log + "\">\n<build>\n");
            
            for (Map<String, Object> map : records)
            {
                output.write("<message priority=\"error\"><![CDATA[" + map.get("data") + "]]></message>\n");
            }
            
            output.write("</build>\n</log>");
            output.close();
            
            return temp;
        } catch (Exception ex) {
            logger.info("Exception generating xml file for metadata");
            logger.debug("Exception in metadata source", ex);
        }
        return null;
    }
}