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

package com.nokia.helium.ant.data;

import java.io.IOException;
import org.dom4j.DocumentException;
import org.dom4j.Element;

/**
 * An Ant library root object.
 */
public class AntlibMeta extends RootAntObjectMeta {

    public AntlibMeta(AntFile antFile, Element node) throws DocumentException, IOException {
        super(antFile, node);

        // Only parse a project comment if it is marked
        if (!getComment().isMarkedComment()) {
            setComment(getEmptyComment());
        }
    }

    @Override
    public String getName() {
        return getFile().getName();
    }
}
