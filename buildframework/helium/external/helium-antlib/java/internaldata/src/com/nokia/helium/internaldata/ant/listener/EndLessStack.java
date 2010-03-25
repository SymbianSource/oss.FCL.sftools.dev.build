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

package com.nokia.helium.internaldata.ant.listener;

import java.util.Stack;
/**
 * Object to keep the elements in a stack, it supports both pop and peek (return element is kept in the stack).
 * 
 * @param <E> The type applied to the stack.
 */
public class EndLessStack<E> extends Stack<E> {
    public static final long serialVersionUID = -1L;
    private E defaultElement;
    
    /**
     * Create a stack with a defaultElement as the default element.
     * @param defaultElement The default element to use.
     */
    public EndLessStack(E defaultElement) {
        super();
        this.defaultElement = defaultElement;
    }

    /**
     * Create a stack with a null default element.
     */
    public EndLessStack() {
        super();
        this.defaultElement = null;
    }

    /**
     * This return the top most element out from the stack.
     * If the stack is empty it returns the defaultElement.
     * @return element 
     */
    public E pop() {
        E element = super.pop();
        if (element != null)
            return element;
        return defaultElement;
    }
    
    /** 
     * Endless stack is never empty. 
     */
    public boolean empty() {
        return false;
    }
    
    /**
     * This return the top most element from the stack.
     * If the stack is empty it returns the defaultElement.
     * The return element is kept in the stack.
     * @return element 
     */
    public E peek() {
        if (!super.empty()) {
            E element = super.peek();
            return element;
        }
        return defaultElement;
    }

    /**
     * Get default element.
     * This is the object which will get returned if the internal stack gets empty.
     * @return element 
     */
    public Object getDefaultElement() {
        return defaultElement;
    }

    /**
     * Set default element.
     * @return element 
     */
    public void setDefaultElement(E defaultElement) {
        this.defaultElement = defaultElement;
    }
    
}
