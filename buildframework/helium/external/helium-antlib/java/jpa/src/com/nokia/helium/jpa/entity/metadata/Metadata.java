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

package com.nokia.helium.jpa.entity.metadata;

import java.util.ArrayList;
import javax.persistence.FlushModeType;
import org.apache.log4j.Logger;
import java.util.List;
import javax.persistence.MapKeyColumn;
import javax.persistence.Column;
import javax.persistence.Basic;
import javax.persistence.FetchType;
import javax.persistence.Entity;
import javax.persistence.GeneratedValue;
import javax.persistence.GenerationType;
import javax.persistence.Id;
import javax.persistence.OneToMany;
import javax.persistence.EntityManager;
import java.util.Hashtable;
import javax.persistence.Query;
import javax.persistence.CascadeType;
import com.nokia.helium.jpa.ORMCommitCount;
import com.nokia.helium.jpa.ORMEntityManager;

/**
 * Interface Class to store all the metadata information.
 */

@Entity
public class Metadata {

    private static Logger log = Logger.getLogger(Metadata.class);
    
    private static String[] priorityNames = {"FATAL", "ERROR", "WARNING", "INFO",
        "REAMARK", "CRITICAL", "DEFAULT"};

    private transient ORMEntityManager manager;

    private transient String logPath;

    @Basic
    @Column(unique = true, nullable = false)
    private String name;


    @Id
    @GeneratedValue(strategy = GenerationType.SEQUENCE)
    private int id;

    @OneToMany(mappedBy = "metadata",
            fetch = FetchType.LAZY, cascade = CascadeType.ALL)
    private Hashtable<String, LogFile> logFiles;

    @OneToMany(mappedBy = "metadata",
            fetch = FetchType.LAZY, cascade = CascadeType.ALL)
    @MapKeyColumn(name = "PRIORITY", insertable = false, updatable = false)
    private Hashtable<String, Priority> priorities;


    private Hashtable<String, Component> components;
 
    private List<MetadataEntry> entries;

    /**
     * Default Constructor.
     */
    public Metadata() {
    }

    /** Constructor.
     * @param nm - name to be looked for in the persistence.xml file
     * for database information.
     */
    public Metadata(String nm) {
        name = nm;
    }

    /** Constructor.
     *  @param mgr - entity manager using which the data to be
     *  written to database.
     *  @param path - log path for which data to be written to.
     */
    public Metadata(ORMEntityManager mgr, String path) {
        manager = mgr;
        if (logPath == null) {
            //System.out.println("addEntry logPath null");
            logPath = path;
            initializeLogPath();
        }
    }

    /**
     * Helper function to set the name of the JPA entity manager to
     * be used.
     * @param nm - name to be looked for in the persistence.xml file
     * for database information.
     */
    public void setName(String nm) {
        name = nm;
    }

    /**
     * Helper function to get the name of the JPA entity manager to
     * being used.
     * @return nm - name to be looked for in the persistence.xml file
     * for database information.
     */
    public String getName() {
        return name;
    }


    /**
     * Helper function to return the list of Logfiles stored
     * in the database.
     * @return Hash table of logpath with logfile object
     * stored in the database.
     */
    public Hashtable<String, LogFile> getLogFiles() {
        return logFiles;
    }

    /**
     * Helper function to persist the components,
     * in the database.
     * @param componentsList of component name with component object.
     * stored in the database.
     */
    public void setComponents(Hashtable<String, Component> componentsList) {
        components = componentsList;
    }

    /**
     * Helper function to persist logfile objects in the database.
     * @param logFilesList logpath with logfile object.
     */
    public void setLogFiles(Hashtable<String, LogFile> logFilesList) {
        logFiles = logFilesList;
    }

    public String getLogPath() {
        return logPath;
    }
    /**
     * Helper function to persist metadata entry lists in the db.
     * @param entriesList List of entries to persist.
     */
    public void setEntries(List<MetadataEntry> entriesList) {
        entries = entriesList;
    }

    /**
     * Helper function to return the list of persisted entries currently
     * in memory.
     * @return list of metadata entries currently in memory.
     */
    public List<MetadataEntry> getEntries() {
        return entries;
    }

    /**
     * Helper function to set the logpath of the current entry.
     * @param path logpath associated with this entry.
     */
    public void setLogPath(String path) {
        logPath = path;
    }

    /**
     * Helper function to set the priority list.
     * @param prtList.
     */
    public void setPriorities(Hashtable<String, Priority> prtList) {
        priorities = prtList;
    }

    /**
     * Helper function to initialize the components currently in
     * the database. This is cached in memory so that before persisting
     * the cached info is checked for performance optmization.
     * @param path - path associated with the component.
     * @param logFile - logfile object associated with the component.
     */
    @SuppressWarnings("unchecked")
    public void initComponents(String path, LogFile logFile) {
        logPath = path;
        components = new Hashtable<String, Component>();
        if (logFile != null) {
            //System.out.println("logfile id: " + logFile.getId());
            List<Component> componentList =
                (List<Component>) manager.getEntityManager().createQuery(
                    "SELECT c FROM Component c WHERE c.logPathID = :pathId")
            .setParameter("pathId", logFile.getId()).getResultList();
            for (Component comp : componentList) {
                components.put(comp.getComponent(), comp);
            }
        }
    }

    /**
     * Initialize the priority table, caches in memory for
     * performance.
     */
    @SuppressWarnings("unchecked")
    public void initPriorities() {
        priorities = new Hashtable<String, Priority>();
        List<Priority> priorityList =
            (List<Priority>) manager.getEntityManager().createQuery(
                "SELECT p FROM Priority p")
            .getResultList();
        for (Priority priority : priorityList) {
            //System.out.println("priority value: " + priority.getPriority());
            priorities.put(priority.getPriority(), priority);
        }
    }

    /**
     * Load the required data to be cached from database.
     * @param path - db path.
     */
    @SuppressWarnings("unchecked")
    private void loadFromDB(String path) {
        LogFile logFile = null;
        logFiles = new Hashtable<String, LogFile>();
        List<LogFile> logFilesList =
            (List<LogFile>) manager.getEntityManager().createQuery(
                "SELECT l FROM LogFile l").getResultList();
        for (LogFile file : logFilesList) {
            log.debug("getting logfile from db: " + file.getPath());
            logFiles.put(file.getPath(), file);
        }
        //manager.getEntityManager().clear();
        logFile = logFiles.get(path);
        if (logFile == null) {
            populateDB(path);
        } else {
            initComponents(path, logFile);
            List<MetadataEntry> entriesList = new ArrayList<MetadataEntry>();
            setEntries(entriesList);
        }
        initPriorities();
    }

    /**
     * Internal function to persist an object into the database.
     * @param obj - object to be stored in the data.
     */
    private void persist(Object obj) {
        synchronized (manager) {
            EntityManager em = manager.getEntityManager();
            ORMCommitCount countObject = manager.getCommitCountObject();
            //log.debug("object: " + obj);
            //log.debug("object: " + em);
            em.persist(obj);
            countObject.decreaseCount();
            if (countObject.isCommitRequired()) {
                countObject.reset();
                em.getTransaction().commit();
                em.clear();
                em.getTransaction().begin();
            }
        }
    }

    /**
     * Internal function to populate the priorities into the cache.
     */
    private void populatePriorities() {
        Hashtable<String, Priority> priorityList = new Hashtable<String, Priority>(); 
        setPriorities(priorityList);
        for (String priorityName : priorityNames) {
            Priority priority = new Priority();
            priority.setPriority(priorityName);
            priorityList.put(priorityName, priority);
            log.debug("populating priorities: " + priorityName);
            persist(priority);
        }
    }

    /**
     * Internal function to load data from database.
     * @param path - db path
     */
    private void populateDB(String path) {
        setLogPath(path);
        Hashtable<String, LogFile> logFileList =
            new Hashtable<String, LogFile>();
        //entityManager.merge(logFileList);
        setLogFiles(logFileList);
        log.debug("populatedb: " + path);
        checkAndAddLogPath();
        Hashtable<String, Component> componentsList =
            new Hashtable<String, Component>();
        //entityManager.merge(componentsList);
        setComponents(componentsList);
        List<MetadataEntry> entriesList = new ArrayList<MetadataEntry>();
        setEntries(entriesList);
    }

    /**
     * Internal function to cache the logpath for performance.
     */
    private void initializeLogPath() {
        EntityManager em = manager.getEntityManager();
        Query q = em.createQuery("select m from LogFile m");
        name = "metadata";
        if (q.getResultList().size() == 0) {
            log.debug("query result: size" + q.getResultList().size());
            populatePriorities();
            populateDB(logPath);
        } else {
            log.debug("loading from db: " + logPath);
            loadFromDB(logPath);
        }
        //em.clear();
    }

    /**
     * Adds the log entry to the database.
     * @param entry - logentry which is to be written to db.
     */
    public void addEntry(LogEntry entry) {

        String comp = entry.getComponent();
        Component component = null;
        if (comp != null) {
            component = checkAndAddComponent(comp);
            float elapsedTime = entry.getElapsedTime();
            String priority = entry.getPriorityText();
            int lineNo = entry.getLineNumber();
            String logText = entry.getText();
            log.debug("elapsedTime: " + elapsedTime);
            log.debug("comp: " + comp);
            if (elapsedTime != -1) {
                addElapsedTime(component, elapsedTime);
            } else if (!priority.equals("default")) {
                addMetadata(priority, component, lineNo, logText);
            } else {
                WhatEntry whatEntry = entry.getWhatEntry();
                if (whatEntry != null) {
                    List<WhatLogMember> members = whatEntry.getMembers(); 
                    if (members != null) {
                        for (WhatLogMember member : members) {
                            if (member != null) {
                                addWhatLogMember(component, member.getMember(),
                                        member.getMemberExists());
                            }
                        }
                    }
                }
            }
        }
    }

    
    /**
     * Internal function to add what log member to the database.
     * @param component for which to record the elapsed time
     * @param whatLogMember - an entry from whatlog output
     * @param memberExists - is the whatlog entry exists in the file system.
     */
    private void addWhatLogMember(Component component,
            String whatLogMember, boolean memberExists) {
        //Todo: handle duplicate whatlog member entry
        WhatLogEntry entry = new WhatLogEntry();
        entry.setMember(whatLogMember);
        entry.setMissing(!memberExists);
        entry.setComponent(component);
        persist(entry);
    }

    /**
     * Internal function to add log path only if it is not already
     * there in the cached entry from database.
     * @return LogFile object related to the logpath.
     */
    private LogFile checkAndAddLogPath() {
        LogFile logFile = logFiles.get(logPath);
        log.debug("checkandaddlogpath:logpath" + logPath);
        log.debug("checkandaddlogpath:logFile" + logFile);
        if (logFile == null) {
            logFile = new LogFile();
            logFile.setPath(logPath);
            persist(logFile);
            logFiles.put(logPath, logFile);
        }
        return logFile;
    }

    /**
     * Internal function to add elapsed tim to the database.
     * @param component for which to record the elapsed time
     * @param elapsedTime - time to be recorded.
     */
    private void addElapsedTime(Component component, double elapsedTime) {
        ComponentTime componentTime = new ComponentTime();
        componentTime.setComponent(component);
        componentTime.setDuration(elapsedTime);
        persist(componentTime);
    }

    /**
     * Internal function to add component if not exist
     * in the cached entries from database.
     * @param comp - component Name to be added.
     * @return either new component / existing component from cache.
     */
    private Component checkAndAddComponent(String comp) {
        //System.out.println("checkAndAddComponent: comp: "+ comp);
        Component component = components.get(comp);
        if (component == null) {
            component = new Component();
            log.debug("checkandaddcomponent: logpath" + logPath);
            log.debug("checkandaddcomponent: logpath" + logFiles);
            component.setLogFile(logFiles.get(logPath));
            component.setComponent(comp);
            persist(component);
            components.put(comp, component);
        }
        return component;
    }

    /**
     * Function provides the Priority object for the string
     * priority.
     * @param prty - priority string
     * @return Priority object for the prioirty string.
     */
    private Priority getPriority(String prty) {
        Priority retValue = priorities.get(prty.toUpperCase());
        if (retValue == null) {
            retValue = priorities.get(priorityNames[0]);
        }
        log.debug("priority:getPriority: " + prty);
        return retValue;
    }

    /**
     * Internal function to add the entry to the database.
     * priority.
     * @param priority - Priority of the entry
     * @param component - component info for the entry
     * @param lineNo - line number at which the severity is captured.
     * @param logText - text about the severity info to be recorded.
     */
    private void addMetadata(String priority, Component component,
            int lineNo, String logText) {
        MetadataEntry entry = new MetadataEntry();
        log.debug("logfile : " + component.getLogFile().getPath());
        entry.setLogFile(component.getLogFile());
        entry.setComponent(component);
        entry.setLineNumber(lineNo);
        entry.setPriority(getPriority(priority));
        log.debug("error text message: " + logText);
        entry.setText(logText);
        persist(entry);
    }

    /**
     * Removes the entries for a particular log.
     * priority.
     */
    public final void removeEntries() {
        EntityManager em = manager.getEntityManager();
        LogFile file = (LogFile)executeSingleQuery("select l from LogFile l where l.path like '%" + logPath + "'");
        if ( file != null ) {
            log.debug("removing entries for : " + file.getPath());
            int pathId = file.getId();
            removeEntries("DELETE FROM MetadataEntry AS m where m.COMPONENT_ID in (select COMPONENT_ID from Component where LOGPATH_ID= " + pathId + ")");
            removeEntries("DELETE FROM ComponentTime AS ctime where ctime.COMPONENT_ID in (select COMPONENT_ID from Component where LOGPATH_ID= " + pathId + ")");
            removeEntries("DELETE FROM WhatLogEntry AS wentry where wentry.COMPONENT_ID in (select COMPONENT_ID from Component where LOGPATH_ID= " + pathId + ")");
            removeEntries("DELETE FROM Component AS c where c.LOGPATH_ID = " + pathId);
            removeEntries("DELETE FROM LogFile AS l where l.LOGPATH_ID = " + pathId);
            removeEntries("DELETE FROM LogFile l where l.LOGPATH_ID = " + pathId);
        }
    }

    /**
     * Internal function execute query which results in single record.
     * @param queryString - query string for whcih the result to be obtained.
     * @return object - record from the executed query.
     */
    private Object executeSingleQuery (String queryString) {
        EntityManager em = manager.getEntityManager();
        Query query = em.createQuery(queryString);
        query.setHint("eclipselink.persistence-context.reference-mode", "WEAK");
        query.setHint("eclipselink.maintain-cache", "false");
        query.setHint("eclipselink.read-only", "true");
        query.setFlushMode(FlushModeType.COMMIT);
        Object obj = null;
        try {
            obj = query.getSingleResult();
        } catch (javax.persistence.NoResultException nex) {
            log.debug("no results:", nex);
        } catch (javax.persistence.NonUniqueResultException nux) {
            log.debug("more than one result returned:", nux);
        }
        return obj;
    }

    /**
     * Internal function to remove the entries from db.
     * @param queryString - query string for whcih the result to be obtained.
     */
    private void removeEntries(String queryString) {
        EntityManager em = manager.getEntityManager();
        Query query = em.createNativeQuery(queryString);
        query.setHint("eclipselink.persistence-context.reference-mode", "WEAK");
        query.setHint("eclipselink.maintain-cache", "false");
        query.setFlushMode(FlushModeType.COMMIT);
        try {
            int deletedRecords = query.executeUpdate();
            log.debug("total records deleted " + deletedRecords 
                    + "for query:" + queryString);
        } catch (javax.persistence.NoResultException nex) {
            log.debug("no results:", nex);
        } catch (javax.persistence.NonUniqueResultException nux) {
            log.debug("more than one result returned:", nux);
        }
    }

    /**
     * Helper class to store the log entry , used to write to the database
     * 
     * @param databasePath The path to the database
     */
    public static class LogEntry
    {
        private String text;

        private PriorityEnum priority;

        private String component;
        
        private int lineNumber;
        
        private String logPath;
        
        private float elapsedTime;
        
        private String priroityText;
        
        private WhatEntry whatEntry;

    /**
     * Constructor for the helper class 
     */
        public LogEntry(String text, PriorityEnum priority, String component, 
                String logPath, int lineNumber, 
                float time, WhatEntry entry)
        {
            this.text = text;
            this.priority = priority;
            this.component = component;
            this.lineNumber = lineNumber;
            this.logPath = logPath.replace('\'', '/');
            this.elapsedTime = time;
            whatEntry = entry;
        }

    /**
     * Constructor for the helper class 
     */
        public LogEntry(String text, PriorityEnum priority, String component, 
                String logPath, int lineNumber)
        {
            this(text, priority, component, logPath, lineNumber, -1, null);
        }


    /**
     * Constructor for the helper class.
     */
        public LogEntry(String text, String priorityTxt, String component, String logPath, 
                int lineNumber, float time, WhatEntry entry) throws Exception
        {
            PriorityEnum prty = null;
            String prtyText = priorityTxt.trim().toLowerCase();
            priroityText =  prtyText;
            if (prtyText.equals("error")) {
                prty = PriorityEnum.ERROR;
            } else if (prtyText.equals("warning")) {
                prty = PriorityEnum.WARNING;
            } else if (prtyText.equals("fatal")) {
                prty = PriorityEnum.FATAL;
            } else if (prtyText.equals("info")) {
                prty = PriorityEnum.INFO;
            } else if (prtyText.equals("remark")) {
                prty = PriorityEnum.REMARK;
            } else if (prtyText.equals("default")) {
                prty = PriorityEnum.DEFAULT;
            } else if (prtyText.equals("critical")) {
                prty = PriorityEnum.CRITICAL;
            } else {
                log.debug("Error: priority " + prtyText + " is not acceptable by metadata and set to Error");
                prty = PriorityEnum.ERROR;
                priroityText =  "error";
                //throw new Exception("priority should not be null");
            }

            this.logPath = logPath.replace('\\', '/');
            this.text = text;
            priority = prty;
            this.component = component;
            this.lineNumber = lineNumber;
            this.elapsedTime = time;
            whatEntry = entry;
        }

        public void setElapsedTime(float time) {
            this.elapsedTime = time;
        }
    /**
     * Helper function to return to getLogPath
     * @
     */

        public String getLogPath()
        {
            return logPath;
        }

        
        public int getLineNumber()
        {
            return lineNumber;
        }
        
        public String getText()
        {
            return text;
        }

        public void setText(String text)
        {
            this.text = text;
        }

        public PriorityEnum getPriority()
        {
            return priority;
        }

        public String getPriorityText() {
            return priroityText;
        }

        
        public float getElapsedTime() {
            return elapsedTime;
        }

        public void setPriority(PriorityEnum priority)
        {
            this.priority = priority;
        }

        public String getComponent()
        {
            return component;
        }

        public void setComponent(String component)
        {
            this.component = component;
        }
        
        public WhatEntry getWhatEntry() {
            return whatEntry;
        }
        
    }

    /** Levels of log entry types. */
    public enum PriorityEnum
    {
        // The values assigned to these enums should match the 
        // automatically assigned values created in the database table
        FATAL(1), ERROR(2), WARNING(3), INFO(4), REMARK(5), DEFAULT(6), CRITICAL(7);
        private final int value;
        PriorityEnum(int value)
        {
            this.value = value;
        }
        public int getValue() {
            return value;
        }
    
        public  static PriorityEnum getPriorityEnum( int i ) {
            final PriorityEnum[] values  = values();
            return i >= 0 && i < values .length ? values[i] : FATAL;
        }
    };

    /**
     * Helper class to store the Component and output association.
     */
    public static class WhatEntry
    {
        private String component;
        private List<WhatLogMember> members;

    /**
     * Constructor for the helper class 
     */
        public WhatEntry(String comp, List<WhatLogMember> mbrs)
        {
            component = comp;
            members = mbrs;
        }
        
        public String getComponent() {
            return component;
        }

        public List<WhatLogMember> getMembers() {
            return members;
        }
    }


    /**
     * Helper class to store the what log output into orm.
     */
    public static class WhatLogMember {
        private String member;
        private boolean memberExists;

        public WhatLogMember(String mbr, boolean exists) {
            member = mbr;
            memberExists = exists;
        }
        
        public String getMember() {
            return member;
        }
        
        public boolean getMemberExists() {
            return memberExists;
        }
    }
}