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


import javax.persistence.CascadeType;
import javax.persistence.Entity;
import javax.persistence.GeneratedValue;
import javax.persistence.GenerationType;
import javax.persistence.Id;
import javax.persistence.ManyToOne;
import javax.persistence.Column;
import javax.persistence.Basic;
import javax.persistence.JoinColumn;


/**
 *  Entity component time to store the time taken for each
 *  component to build.
 */
@Entity
public class ComponentTime {

    @Id
    @GeneratedValue(strategy = GenerationType.SEQUENCE)
    @Column(name = "COMPONENTTIME_ID")
    private int id;

    @Basic
    private double componentTime;

    @Basic
    @Column(name = "COMPONENT_ID", insertable = false, updatable = false)
    private int componentId;


    @ManyToOne(cascade = CascadeType.REMOVE)
    @JoinColumn(name = "COMPONENT_ID", referencedColumnName = "COMPONENT_ID")
    
    private Component component;

    /**
     *  Helper function to set the associated component.
     *  @param cmpt for which the time to be recorded.
     */
    public void setComponent(Component cmpt) {
        component = cmpt;
    }


    /**Helper function to return the time taken for this component
     *  to build.
     *  @return duration to build this component.
     */
    public double getDuration() {
        return componentTime;
    }

    /**
     *  Helper function to set the duration for this component to build.
     *  @param duration to build this component.
     */

    public void setDuration(double duration) {
        componentTime = duration;
    }
}