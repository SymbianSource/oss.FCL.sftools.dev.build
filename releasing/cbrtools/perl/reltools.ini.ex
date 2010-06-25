# Copyright (c) 2009 Nokia Corporation and/or its subsidiary(-ies).
# All rights reserved.
# This component and the accompanying materials are made available
# under the terms of the License "Eclipse Public License v1.0"
# which accompanies this distribution, and is available
# at the URL "http://www.eclipse.org/legal/epl-v10.html".
# 
# Initial Contributors:
# Nokia Corporation - initial contribution.
# 
# Contributors:
# 
# Description:
# 

#*****************************************#
# Reltools.ini configuration example file #
#*****************************************#

# Common configuration options
# ----------------------------
diff_tool 			windiff
require_internal_versions
categorise_binaries
categorise_exports
disallow_unclassified_source

# Archives containing your releases
# ---------------------------------
archive_path	my_releases	\\myserver\builds\componentised\my_build_config	/Optional_path_on_remote_server
archive_path	my_other_releases	\\myserver\builds\componentised\my_other_build_config	/Optional_path_on_remote_server

# Remote server configuration
# ----------------------------
export_data_file       		\\myserver\config_man\reltools\export_data.csv
pgp_config_path        		\\myserver\config_man\reltools
pgp_tool                        pgp           # Must be pgp or gpg
pgp_encryption_key              0x12345678
remote_site_type                ftp           # Common values are netdrive and ftp
remote_host		 	ourftp.mycompany.com.invalid
remote_username		 	myusername
remote_password		 	mypassword
remote_logs_dir		 	/release_logs # Path on server for logs
pasv_transfer_mode
ftp_server_supports_resume
ftp_timeout			30
ftp_reconnect_attempts		5
proxy_host                      myproxyftpserver # Only valid if using remote_site_type proxy
proxy_username                  myproxyusername
proxy_password                  myproxypassword
