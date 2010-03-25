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

package com.nokia.maven.scm.provider.hg;

import java.io.File;
import java.net.MalformedURLException;
import java.net.URL;
import java.util.ArrayList;
import java.util.List;

import com.nokia.maven.scm.provider.hg.command.log.HgChangeLogCommand;
import org.apache.maven.scm.command.changelog.ChangeLogScmResult;

import org.apache.log4j.Logger;
import org.apache.maven.scm.CommandParameters;
import org.apache.maven.scm.ScmException;
import org.apache.maven.scm.ScmFileSet;
import org.apache.maven.scm.ScmResult;
import org.apache.maven.scm.command.checkout.CheckOutScmResult;
import org.apache.maven.scm.command.export.ExportScmResult;
import org.apache.maven.scm.command.remove.RemoveScmResult;
import org.apache.maven.scm.command.branch.BranchScmResult;
import org.apache.maven.scm.command.update.UpdateScmResult;
import org.apache.maven.scm.command.tag.TagScmResult;
import org.apache.maven.scm.provider.ScmProviderRepository;
import org.apache.maven.scm.provider.hg.HgScmProvider;
import org.apache.maven.scm.repository.ScmRepository;
import org.apache.maven.scm.repository.ScmRepositoryException;

import com.nokia.maven.scm.command.pull.PullScmResult;
import com.nokia.maven.scm.command.tags.TagsScmResult;
import com.nokia.maven.scm.command.info.InfoScmResult;
import com.nokia.maven.scm.provider.ScmProviderExt;
import com.nokia.maven.scm.provider.hg.command.init.HgInitCommand;
import com.nokia.maven.scm.provider.hg.command.pull.HgPullCommand;
import com.nokia.maven.scm.provider.hg.command.remove.HgRemoveCommand;
import com.nokia.maven.scm.provider.hg.command.tags.HgTagsCommand;
import com.nokia.maven.scm.provider.hg.command.info.HgInfoCommand;
import com.nokia.maven.scm.provider.hg.command.update.HgUpdateCommand;
import com.nokia.maven.scm.provider.hg.command.checkout.HgCheckOutCommand;
import com.nokia.maven.scm.provider.hg.command.export.HgExportCommand;
import com.nokia.maven.scm.provider.hg.command.branch.HgBranchCommand;
import com.nokia.maven.scm.provider.hg.command.tag.HgTagCommand;
import com.nokia.maven.scm.provider.hg.repository.HgScmProviderRepository;

/**
 * The SCM provider for Mercurial (hg).
 */
public class HgScmProviderExt extends HgScmProvider implements ScmProviderExt {

    private static Logger log = Logger.getLogger(HgScmProviderExt.class);
    
    public ScmResult init(ScmRepository repository) throws ScmException {
        log.info("HgScmProviderExt.init()");

        HgInitCommand command = new HgInitCommand();

        return command.executeInitCommand(repository.getProviderRepository());
    }

    @Override
    public CheckOutScmResult checkout(ScmProviderRepository repository,
            ScmFileSet fileSet, CommandParameters parameters)
            throws ScmException {

        HgCheckOutCommand command = new HgCheckOutCommand();
        command.setLogger(getLogger());
        return (CheckOutScmResult) command.executeCommand(repository, fileSet,
                parameters);
    }

    @Override
    public ChangeLogScmResult changelog(ScmProviderRepository repository,
            ScmFileSet fileSet, CommandParameters parameters)
            throws ScmException {

        HgChangeLogCommand command = new HgChangeLogCommand();
        command.setLogger(getLogger());
        return (ChangeLogScmResult) command.executeCommand(repository, fileSet,
                parameters);
    }

    public PullScmResult pull(ScmRepository repository, File path)
            throws ScmException {
        HgPullCommand command = new HgPullCommand();
        command.setLogger(getLogger());
        return (PullScmResult) command.executeCommand(repository
                .getProviderRepository(), new ScmFileSet(path),
                new CommandParameters());
    }

    @Override
    public UpdateScmResult update(ScmProviderRepository repository,
            ScmFileSet fileSet, CommandParameters parameters)
            throws ScmException {
        HgUpdateCommand command = new HgUpdateCommand();
        command.setLogger(getLogger());
        return (UpdateScmResult) command.executeCommand(repository, fileSet,
                parameters);
    }

    public TagsScmResult tags(ScmRepository repository, ScmFileSet fileSet,
            CommandParameters parameters) throws ScmException {
        HgTagsCommand command = new HgTagsCommand();
        command.setLogger(getLogger());
        return (TagsScmResult) command.executeCommand(repository
                .getProviderRepository(), fileSet, parameters);
    }
    
    public InfoScmResult info(ScmRepository repository, ScmFileSet fileSet,
            CommandParameters parameters) throws ScmException {
        HgInfoCommand command = new HgInfoCommand();
        command.setLogger(getLogger());
        return (InfoScmResult) command.executeCommand(repository
                .getProviderRepository(), fileSet, parameters);
    }

    @Override
    public RemoveScmResult remove(ScmProviderRepository repository,
            ScmFileSet fileSet, CommandParameters parameters)
            throws ScmException {
        HgRemoveCommand command = new HgRemoveCommand();
        command.setLogger(getLogger());
        return (RemoveScmResult) command.execute(repository, fileSet,
                parameters);
    }

    protected BranchScmResult branch(ScmProviderRepository repository,
            ScmFileSet fileSet, CommandParameters parameters)
            throws ScmException {
        HgBranchCommand command = new HgBranchCommand();
        command.setLogger(getLogger());
        return (BranchScmResult) command.execute(repository, fileSet,
                parameters);
    }

    protected ExportScmResult export(ScmProviderRepository repository,
            ScmFileSet fileSet, CommandParameters parameters)
            throws ScmException {
        HgExportCommand command = new HgExportCommand();
        command.setLogger(getLogger());
        return (ExportScmResult) command.execute(repository, fileSet,
                parameters);
    }

    @Override
    public TagScmResult tag(ScmProviderRepository repository,
            ScmFileSet fileSet, CommandParameters parameters)
            throws ScmException {
        HgTagCommand command = new HgTagCommand();
        command.setLogger(getLogger());
        return (TagScmResult) command.execute(repository, fileSet, parameters);
    }

    /* From official implementation */
    private final class HgUrlParserResult {
        private List<String> messages = new ArrayList<String>();
        private ScmProviderRepository repository;
        
        public List<String> getMessages() {
            return messages;
        }
        
        public void setMessages(List<String> messages) {
            this.messages = messages;
        }
        
        public ScmProviderRepository getRepository() {
            return repository;
        }
        
        public void setRepository(ScmProviderRepository repository) {
            this.repository = repository;
        }
        
    }

    private HgUrlParserResult parseScmUrl(String scmSpecificUrl) {
        HgUrlParserResult result = new HgUrlParserResult();

        URL url = null;
        log.debug("HgScmProviderExt:parseScmUrl:" + scmSpecificUrl);
        // try if it is an URL
        try {
            url = new URL(scmSpecificUrl);
            HgScmProviderRepository repo = new HgScmProviderRepository(
                    "file://localhost/");
            repo.configure(url);
            result.repository = repo;
        } catch (MalformedURLException e) {
            log.debug("HgScmProviderExt:parseScmUrl:MalformedURLException:"
                    + e.getMessage());
            // if the url is invalid then try a simple file. 
            try {
                result.setRepository(new HgScmProviderRepository(scmSpecificUrl));
            } catch (Throwable et) {
                log.debug("HgScmProviderExt:parseScmUrl:Throwable:"
                        + et.getMessage());
                result.getMessages().add("The filename provided is not valid: "
                        + et.getMessage());
                return result;
            }
        }
        return result;
    }

    /**
     * Overriding default implementation.
     */
    public List<String> validateScmUrl(String scmSpecificUrl, char delimiter) {
        HgUrlParserResult result = parseScmUrl(scmSpecificUrl);
        return result.messages;
    }

    /**
     * Overriding default implementation.
     */
    public ScmProviderRepository makeProviderScmRepository(
            String scmSpecificUrl, char delimiter)
            throws ScmRepositoryException {
        HgUrlParserResult result = parseScmUrl(scmSpecificUrl);

        if (result.messages.size() > 0) {
            throw new ScmRepositoryException("The scm url is invalid.",
                    result.messages);
        }
        return result.repository;
    }

}
