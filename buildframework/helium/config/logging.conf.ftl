<#--
============================================================================ 
Name        : logging.conf.ftl 
Part of     : Helium 

Copyright (c) 2009 Nokia Corporation and/or its subsidiary(-ies).
All rights reserved.
This component and the accompanying materials are made available
under the terms of the License "Eclipse Public License v1.0"
which accompanies this distribution, and is available
at the URL "http://www.eclipse.org/legal/epl-v10.html".

Initial Contributors:
Nokia Corporation - initial contribution.

Contributors:

Description:

============================================================================
--> 
[formatters]
keys: simple,detailed
 
[handlers]
keys: console,syslog
 
[loggers]
keys: root,dp
 
[formatter_simple]
format: %(levelname)s:%(name)s:%(message)s

[formatter_detailed]
format: %(levelname)s:%(name)s: %(module)s:%(lineno)d: %(message)s

[handler_console]
class: StreamHandler
args: []
formatter: simple

[handler_syslog]
class: handlers.SysLogHandler
args: [('myhost.mycorp.net', handlers.SYSLOG_UDP_PORT), handlers.SysLogHandler.LOG_USER]
formatter: detailed

[logger_root]
level: INFO
handlers: syslog

[logger_dp]
<#if ant?keys?seq_contains("dp.debug") || ant?keys?seq_contains("debug")>
level: DEBUG
<#else>
level: INFO
</#if>
handlers: console
qualname: dp