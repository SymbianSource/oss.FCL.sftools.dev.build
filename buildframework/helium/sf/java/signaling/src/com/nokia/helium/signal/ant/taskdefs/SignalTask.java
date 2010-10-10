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

package com.nokia.helium.signal.ant.taskdefs;

import java.util.Vector;

import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.Project;
import org.apache.tools.ant.Target;
import org.apache.tools.ant.Task;

import com.nokia.helium.signal.ant.Signals;
import com.nokia.helium.signal.ant.types.SignalInput;
import com.nokia.helium.signal.ant.types.SignalNotifierInput;

/**
 * This task provide a way to raise a signal.
 * If the provided result is different from 0 then the mentioned signal
 * is raised.
 * 
 * You can emit a signal based from the signal task, its behavior will get defined by the
 * nested signalInput element. e.g:
 * <pre>
 * &lt;target name=&quot;raise-signal&quot;&gt;
 *   &lt;-- Some computation that sets result property --&gt;
 *   &lt;property name=&quot;result&quot; value=&quot;1&quot;/&gt;
 *   
 *   &lt;hlm:signal name=&quot;compileSignal&quot; result=&quot;${result}&quot;&gt;
 *       &lt;-- Let's refer to some existing signal input configuration --&gt;
 *       &lt;hlm:signalInput refid=&quot;testDeferredSignalInput&quot; /&gt;
 *   &lt;/hlm:signal&gt;
 * &lt;/target&gt;
 * </pre>
 * 
 * The execution of the <code>signal</code> task will behave depending on the <code>compileSignal</code> configuration,
 * if not defined the build will fail.
 * 
 * @ant.task name="signal" category="Signaling"
 */
public class SignalTask extends Task {

    private String name;
    private String message;
    private Integer result;

    private Vector<SignalNotifierInput> signalNotifierInputs = new Vector<SignalNotifierInput>();
    
    /**
     * Create a nested signalNotifierInput element.
     * @return a SignalNotifierInput instance
     */   
    public SignalNotifierInput createSignalNotifierInput() {
        SignalNotifierInput input =  new SignalNotifierInput();
        add(input);
        return input;
    }

    /**
     * Get the nested SignalNotifierInput. Only the first element will be returned.
     * @return null if the list is empty of the first element.
     */
    public SignalNotifierInput getSignalNotifierInput() {
        if (signalNotifierInputs.isEmpty()) {
            return null;
        }
        return (SignalNotifierInput)signalNotifierInputs.elementAt(0);
    }
    
    /**
     * Add a SignalNotifierInput kind of element.
     * @param filter to be added to the filterset
     */
    public void add(SignalNotifierInput input) {
        signalNotifierInputs.add(input);
    }
    
    
    /**
     * Error message sent to the user.
     * @ant.not-required Default message will be sent.
     */
    public void setMessage(String message) {
        this.message = message;
    }

    /**
     * Reference of the signal to emit. The referenced object
     * must be a signalInput.
     * 
     * @ant.required
     */
    public void setName(String name) {
        this.name = name;
    }

    /**
     * integer value representing the number of errors.
     * 
     * @ant.no-required Default is 0.
     */
    public void setResult(int result) {
        this.result = new Integer(result);
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public void execute() {
        if (name == null && getSignalNotifierInput() == null) {
            throw new BuildException("'name' attribute is not defined.");
        }
        if (name != null && getSignalNotifierInput() != null) {
            log("The usage of name and nested signalInputNotifier at the same time is deprecated.", Project.MSG_WARN);
            log("'name' attribute will be ignored.", Project.MSG_WARN);
            name = null;
        }
        if (result == null) {
            result = new Integer(0);
        }
        SignalNotifierInput config = null;
        String signalName = null;
        if (name != null) {
            signalName = name;
            Object configObject = getProject().getReference(name);
            if (configObject != null && configObject instanceof SignalInput) {
                config = new SignalNotifierInput();
                config.setProject(getProject());
                config.add((SignalInput)configObject);
            } else {
                throw new BuildException("name attribute (" + name + ") is not refering to a signalInput");
            }
        } else {
            config = getSignalNotifierInput();
            signalName = config.getSignalInput().getName();
        }

        // notify the user
        String targetName = "unknown";  
        Target target = this.getOwningTarget();
        if (target != null) {
            targetName = target.getName();
        }

        if (message == null) {
            message = "Expected result was 0, actual result was " + result;
        }
        log(signalName + ": " + targetName + ": " + message);

        Signals.getSignals().processSignal(getProject(), config, signalName, 
                targetName, message, result.intValue() != 0);            
    }

}
