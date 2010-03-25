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

import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.Task;
import org.apache.tools.ant.Target;
import java.util.Vector;
import com.nokia.helium.signal.ant.SignalList;
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
public class Signal extends Task {

    private String name;
    private String message;
    private Integer result;

    private Vector<SignalNotifierInput> signalNotifierInputs = new Vector<SignalNotifierInput>();
    
    public String getMessage() {
        return message;
    }

    /**
     * Helper function called by ant to create the new signalinput
     */
    public SignalNotifierInput createSignalNotifierInput() {
        SignalNotifierInput input =  new SignalNotifierInput();
        add(input);
        return input;
    }

    public SignalNotifierInput getSignalNotifierInput() {
        return (SignalNotifierInput)signalNotifierInputs.elementAt(0);
    }
    /**
     * Helper function to add the created signalinput
     * @param filter to be added to the filterset
     */
    public void add(SignalNotifierInput input) {
        signalNotifierInputs.add(input);
    }
    
    
    /**
     * Error message.
     * 
     * @ant.not-required
     */
    public void setMessage(String message) {
        this.message = message;
    }


    public String getName() {
        return name;
    }

    /**
     * Signal name to emit.
     * 
     * @ant.required
     */
    public void setName(String name) {
        this.name = name;
    }

    /**
     * integer value representing the number of errors.
     * 
     * @ant.required
     */
    public void setResult(int result) {
        this.result = new Integer(result);
    }

    @Override
    public void execute() {
        if (name == null)
            throw new BuildException("'name' attribute is not defined.");
        if (result == null) {
            result = new Integer(0);
        }

        SignalList signalList = new SignalList(getProject());
        boolean failStatus = result.intValue() != 0; 
        if (failStatus) {
            // keep same message as earlier.
            log(name
                    + ": "
                    + name
                    + " signal failed. Expected result was 0, actual result was "
                    + result);

            if (message == null) {
                message = "Expected result was 0, actual result was " + result;
            }
        }
        
        // notify the user
        String targetName = "signalExceptionTarget";  
        Target target = this.getOwningTarget();
        if (target != null) {
            targetName = target.getName();
        }

        if (signalNotifierInputs.isEmpty()) {          
            Object config = getProject().getReference(name);
            if (config == null) {
                throw new BuildException("Could not find signal config for signal name: " + name);
            }
            signalList.sendSignal(getName(), result.intValue() != 0);
            if (result.intValue() != 0) {
                // keep same message as earlier.
                log(name
                        + ": "
                        + name
                        + " signal failed. Expected result was 0, actual result was "
                        + result);

                if (message == null) {
                    message = "Expected result was 0, actual result was " + result;
                }
                signalList.fail(getName(), this.getOwningTarget().getName(), message);
            }
            
        } else {
            signalList.processForSignal(getProject(), getSignalNotifierInput(), getName(),
                targetName, message, failStatus);
        }
    }

}
