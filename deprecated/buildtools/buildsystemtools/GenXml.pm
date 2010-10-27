# Copyright (c) 2003-2009 Nokia Corporation and/or its subsidiary(-ies).
# All rights reserved.
# This component and the accompanying materials are made available
# under the terms of "Eclipse Public License v1.0"
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

package GenXml;
  
  use strict;
  
  use FindBin;
  use lib "$FindBin::Bin/lib";
  use XML::DOM;
  use XML::DOM::ValParser;
  
  # produces the "Use of uninitialized value in concatenation (.) or string" warning
  use XML::XQL;
  use XML::XQL::DOM;
  
  # Variable to indicate the version of xml file used.  It will be set by subroutine Parse_xml
  my $iVer = 1;
  
  # Used by debug prints
  #my $count;
  
my ($gHiResTimer) = 0; 		#Flag - true (1) if HiRes Timer module available
my ($gLogFileH); 		# Log file handle
my ($gEmbeddedLog) = 0; 	# Flag false (0) if logging must include scanlog headers etc
my ($gValidateFailed) = 0; 	# Flag true (1) if the XML validation has failed
my ($gValidate) = 0; 		# Flag true (1) if to do XML validation only

  #assign STDERR to STDOUT so both are printed in the same file, without overwriting lines
  open (STDERR, ">&STDOUT") or die("ERROR: Unable to redirect STDERR to STDOUT: $!");
  select((select(STDOUT), $|=1)[0]);
  select((select(STDERR), $|=1)[0]);


# Check if HiRes Timer is available
if (eval "require Time::HiRes;") {
  $gHiResTimer = 1;
} else {
  print "Cannot load HiResTimer Module, install the Perl module Time-HiRes for more accurate timing data\n";
}

# Start
#
# Inputs
# $iXMLSource - ref to array of XML filenames, to be merged into one
# $iLogFile - name of logfile
# $iSourceDir - root of the current source tree
# $iEffectiveDir - root of source tree in which output files will be used
# $iValidate - if true, validate the input and then stop
#
# $iFilter - (optional) filter the merged file against this value
# $iMergedXml - (optional) create file of this name containing the merged XML
# $iConfName - name of the configuration: needed by subsequent arguments
# $iDataOutput - (optional) create file of this name containing the XML build commands
# $iTextOutput - (optional) create file of this name containing the list of components
# $iCBROutput - (optional) create file of this name containing the list of MRP files
#
# Description
# This function merges multiple XML files into one document, then optionally outputs various
# files. 
#
sub Start
{
  my ($iXmlSource, $iDataOutput, $iLogFile, $iSourceDir, $iConfName, $iMergedXml, $iValidate, $iTextOutput, $iCBROutput, $iFilter, $iEffectiveDir) = @_;
  
  # Set global validation Flag
  $GenXml::gValidate = $iValidate;

  my $doc;
  
  if ($iLogFile)
  {
    # Open Log file
    $GenXml::gLogFileH = IO::File->new("> $iLogFile")
      or die "ERROR: RealTimeBuild: Couldn't open $iLogFile for writing: $!\n";
    $gEmbeddedLog = 0; # Generate scanlog-compatible log format
  } else {
    $GenXml::gLogFileH = *STDOUT;
    $gEmbeddedLog = 1; # Assume that we are embedded in a scanlog-format log file
  }

  if (!$gEmbeddedLog)
  {
    # Logfile headers
    print $GenXml::gLogFileH "===-------------------------------------------------\n";
    print $GenXml::gLogFileH "=== Genxml\n";
    print $GenXml::gLogFileH "===-------------------------------------------------\n";
    print $GenXml::gLogFileH "=== Genxml started ".localtime()."\n";
  }
  
  # $iSourceDir must end in a \
  # Add a \ if not present
  # And make sure they are in windows style
  if ($iSourceDir !~ /\\$/)
  {
    $iSourceDir =~ s/\//\\/g;
    $iSourceDir .= "\\";
  }
  if ($iEffectiveDir !~ /\\$/)
  {
    $iEffectiveDir =~ s/\//\\/g;
    $iEffectiveDir .= "\\";
  }

  # Parse all the files into one DOM doc
  $doc = &Parse_files($iXmlSource, \$iVer);
  # ... XML::DOM::Document was created sucessfully ...
	  
  # Exit here if validating only
  exit if ($GenXml::gValidate);
	  
  # Try normalising it
  $doc->normalize;
	  
  # filter it, if desired
  if ($iFilter && $iVer == 1)  {
    &logfileHeader("Filtering model against $iFilter");
    &Filter_doc($doc, $iFilter);
    &logfileFooter();
  } elsif ($iFilter && $iVer == 2) { 
    &logfileHeader("Filtering model against $iFilter");
    &Filter_doc2($doc, $iFilter);
    &logfileFooter();
  }
  

  # Debug dump new doc to file
  #~ $doc->printToFile("$iMergedXml") if ($iMergedXml);
  
  #################write only non-empty lines################
  if ($iMergedXml)
  {
    open(HANDLE, "+> $iMergedXml") or die "Error: Can't open $iMergedXml: $!";
    my $MergedXMLString = $doc->toString;
    my @lines = split(/\n/,$MergedXMLString);
    my @tempLines = ();
    foreach (@lines)
    {
      push @tempLines, $_ if $_ !~ /^[\s]*$/;
    }

    $MergedXMLString = join("\n",@tempLines);
    seek(HANDLE,0,0);
    print HANDLE $MergedXMLString;
    truncate(HANDLE,tell(HANDLE));
    close HANDLE;
  }
  #################################
  if ($iConfName)
  {
    # Process the configuration to get the lists of units, tasks and options
    &logfileHeader("Processing configuration $iConfName");
    my ($topunits, $subunits, $options, $tasks) = &process_configuration($doc,$iConfName, $iVer);
    my @topbldList = &compute_bldList($iSourceDir,$iEffectiveDir,$topunits, $iVer); 

    &logfileFooter();

    if ($iTextOutput)
  	  {
	  &logfileHeader("Generating text output $iTextOutput");

	  # Generate old-style text output
	  &write_component_list($doc, $iTextOutput, $iConfName, \@topbldList, $options, $tasks, $iEffectiveDir, $iVer);

	  &logfileFooter();
	  }
	
    if ($iCBROutput)
	  {
	  &logfileHeader("Generating CBR component list $iCBROutput");

	  # Generate list of CBR components for "makecbr"
	  my @allunits;
   #if ($iVer == 1) {
		  @allunits = (@$topunits, @$subunits);
   #} else {
  #  @allunits = (@$topunits);  # No subunits required for the new version of system_definition.xml
   #}
	  my @fullbldList = &compute_bldList($iSourceDir,$iEffectiveDir,\@allunits, $iVer); 
	  
	  &write_CBR_list($iCBROutput, \@fullbldList);

	  &logfileFooter();
	  }
	
    if ($iDataOutput)
	  {
	  &logfileHeader("Generating output XML $iDataOutput");

	  # Generate the output document by applying the tasks to the bldList
	
	  my $ID = 1; # Execute Element ID counter
	  my $Stage = 1; # Execute Element Stage counter

	  my ($outDoc, $docElem, $commands) = &start_output_doc($iConfName, $iVer);

	  process_prebuilt(\$outDoc, \$commands, \$ID, \$Stage, $topunits, 'N', $iVer);
	  foreach my $task (@{$tasks})
		  {
		  &process_task($task, $doc, \$outDoc, \$commands, \$ID, \$Stage, \@topbldList, $options, $iSourceDir, $iEffectiveDir, $iVer);
		  }
	  process_prebuilt(\$outDoc, \$commands, \$ID, \$Stage, $topunits, 'Y', $iVer);

	  $docElem->appendChild($commands);
	  $docElem->addText("\n");
	  #print $outDoc->toString;
	  $outDoc->printToFile($iDataOutput);
	  $outDoc->dispose;

	  &logfileFooter();
	  }
  }
  
  if (!$gEmbeddedLog)
  {
    # Print Genxml log footer
    print $GenXml::gLogFileH "=== Genxml finished ".localtime()."\n";
  }
  
  # Close file handles
  close($GenXml::gLogFileH);
  
  $doc->dispose;
  
}

# Error Processing function for the XML Validation
#
# Throws an exception (with die) when an error is encountered, this
# will stop the parsing process.
# Don't die if a warning or info message is encountered, just print a message.
sub my_fail
{
  my $code = shift;
  
  if ($code < 200)
  {
    print $GenXml::gLogFileH "ERROR: ".XML::Checker::error_string ($code, @_);
    # Set Flag so all the errors are reported before dieing
    $GenXml::gValidateFailed = 1;
  }
  
  # Useful debug output
  print $GenXml::gLogFileH XML::Checker::error_string ($code, @_) if ($GenXml::gValidate);
}

sub my_Unparsed_handler
{
  my ($Parser, $Entity, $Base, $Sysid, $Pubid, $Notation) = @_;
  print $GenXml::gLogFileH "$Entity Unparsed";
  die "ERROR: RealTimeBuild: Processing error\n";
}

# Parse_files
#
# Inputs
# $iXMLSource - ref to array of filenames
# $iVersion - Version of xml file (new or old) ?
#
# Outputs
# $doc - XML DOM doc
#
# Description
# This function merges multiple XML files into one document
sub Parse_files
{
  my ($iXmlSource, $iVersion) = @_;	# Version info passed for conditional processing of xml files
  my (@docs);

  # Load the XML document
  my %expat_options = (KeepCDATA => 1, 
          Handlers => [ Unparsed => \&my_Unparsed_handler ]);
  
  for (my $i = 0; $i < scalar(@$iXmlSource); $i++)
  {
    # Create header for parsing each file
    &logfileHeader(@$iXmlSource[$i]);

    my $parser = new XML::DOM::ValParser (%expat_options);
    XML::DOM::ignoreReadOnly (1);
    local $XML::Checker::FAIL = \&my_fail;
    
    # Useful debug output
    #print "Parsing ".@$iXmlSource[$i]."\n";
    
    $docs[$i] = $parser->parsefile (@$iXmlSource[$i]);
    
    # Create footer for parsing each file
    &logfileFooter();
  }
  
  # Check to see if any of the XML files failed validation and die
  die "ERROR: RealTimeBuild: Validation failed\n" if ($GenXml::gValidateFailed);

# Set the appropriate version number
  for (my $i = 0; $i < scalar(@docs); $i++)
  { if((scalar(@docs))>1)  {
    if ($docs[$i]->getDocumentElement->getAttribute('schema') =~ /^2\./ && 
	$docs[$i]->getDocumentElement->getTagName eq "SystemDefinition" &&
        $docs[1]->getDocumentElement->getTagName eq "SystemBuild")
      {
	$$iVersion = 2; 
	last;
      }
   }
   else
    {
   if ($docs[$i]->getDocumentElement->getAttribute('schema') =~ /^2\./ && 
	$docs[$i]->getDocumentElement->getTagName eq "SystemDefinition")
      {
	$$iVersion = 2; 
	last;
      }
    }
  }
  
  if ($$iVersion == 1)	{  # Docs load now merge into $docs[0] if $iVersion is 1 (i.e. old version of xml file)
    for (my $i = 1; $i < scalar(@docs); $i++)  {
      # Create header for merging each file
      &logfileHeader("Merging in XML file ".@$iXmlSource[$i]);
      &process_node(\($docs[0]->getElementsByTagName("SystemDefinition")),\($docs[$i]->getElementsByTagName("SystemDefinition")), \($docs[0]));
    
      # Re-validate merged file
      local $XML::Checker::FAIL = \&my_fail;
      $docs[0]->check();
    
      # Create footer for merging each file
      &logfileFooter();
      # Check to see if any of the XML files failed validation and die
      die "ERROR: RealTimeBuild: Merged Validation failed\n" if ($GenXml::gValidateFailed);
    }
  } elsif ($$iVersion == 2) {   # Docs load now merge into $docs[$#docs + 1] if $iVersion is 2 (i.e. new version of xml file)
    for (my $i = 1; $i < scalar(@docs); $i++)  {
      # Create header for merging each file
      &logfileHeader("Merging in XML file ".@$iXmlSource[$i]);
      my $mergedDoc = &process_node2(\($docs[0]), \($docs[$i]));
    
      # Re-validate merged file
      local $XML::Checker::FAIL = \&my_fail;
      $mergedDoc->check();
    
      # Create footer for merging each file
      &logfileFooter();
      # Check to see if any of the XML files failed validation and die
      die "ERROR: RealTimeBuild: Merged Validation failed\n" if ($GenXml::gValidateFailed);
      
      $docs[0] = $mergedDoc;      
    }
  }
  return $docs[0];
}

# process_node
#
# Inputs
# $node1 - ref to a node from the master
# $node2 - ref to a node from the slave
# $doc1 - ref to the doc of node1 so we can set the doc owner to the (not DOM spec) to get around WRONG_DOCUMENT_ERR restriction
#
# Outputs
#
# Description
# This function processes a node in two DOM documents, if any children match then it calls itself to process
# the children nodes further
sub process_node
{
  my ($node1, $node2, $doc1) = @_;
  
  # Some nodes need special processing e.g. SystemDefinition
  # This is because there can only be a certain number of these nodes
  # child node / element rules outlined below, this rules are applied to the children of the node in question
  # Child Node / element tag        Rule
  # ------------------------        ----
  # SystemDefinition                Merge the name and revision/schema CDATA as there can be only one of this element
  # systemModel                     Always processed further as there can only be 1 or 0 of these
  # layer                           Same name process further otherwise append child
  # logicalset                      Same name process further otherwise append child
  # logicalsubset                   Same name process further otherwise append child
  # module                          Same name process further otherwise append child
  # component                       Same name process further otherwise append child
  # unit                            Same unitID generate ERROR and not replace child, otherwise append child
  # sub elements of unit            No processing needed as these cannot be merged
  # package                         Same name process further otherwise append child

  # build                           Always processed further as there can only be 1 or 0 of these  
  # unitList                        Same name process further otherwise append child
  # unitRef                         Same unit ignore, different unit append child
  # targetList                      Same name generate ERROR and not replace child, otherwise append child
  # target                          Same name generate ERROR and not replace child, otherwise append child
  # option                          Same name generate ERROR and not replace child, otherwise append child
  # configuration                   Same name generate ERROR and not replace child, otherwise append child
  # sub elements of configuration   No processing needed as these cannot be merged
  
  
  # All other nodes                 Append child
  
  # Useful debug stuff
  #$GenXml::count++;
  #print "enter $GenXml::count\n";
  
  # Handle the special case for the first call to this function with the node containing the SystemDefinition
  if (($$node1->getTagName eq "SystemDefinition") && ($$node2->getTagName eq "SystemDefinition"))
  {
    # Get the name attributes
    my ($name1) = $$node1->getAttribute('name');
    my ($name2) = $$node2->getAttribute('name');
    # Combine the two and set the attribute into the merged file
    $$node1->setAttribute('name',$name1." + ".$name2);
    
    # Get the revision attributes
    my ($revision1) = $$node1->getAttribute('revision');
    my ($revision2) = $$node2->getAttribute('revision');
    # Get the schema attributes
    my ($schema1) = $$node1->getAttribute('schema');
    my ($schema2) = $$node2->getAttribute('schema');
    # If both schema attributes are defined, combine the two and set the attribute into the merged file
    # Note that even if an attribute does not exist in the XML file, XML::DOM returns an empty string (not undef)
    if (($schema1) and ($schema2))
    { # Both files have "new DTD".
      if (($revision1) or ($revision2))
      {
        print $GenXml::gLogFileH "ERROR: Cannot define both schema and revison attributes in same file. Merged file will probably not be usable.\n";
      }
      if ($schema1 eq $schema2)
      { # Both files have same schema attribute. Assign it to merged file
        $$node1->setAttribute('schema',$schema1);
      }
      else
      { # Files have different schema attributes. Combine and assign it to merged file. Warn!!
        print $GenXml::gLogFileH "WARNING: Source file schema attribute values differ ($schema1 vs $schema2). Merged file may not be usable.\n";
        $$node1->setAttribute('schema',$schema1." + ".$schema2);
      }
    }
    # If both revision attributes are defined, combine the two and set the attribute into the merged file
    elsif (($revision1) and ($revision2))
    { # Both files have "old DTD". Retain this code for compatibility
      print $GenXml::gLogFileH "REMARK: Both source files have \"old style\" DTDs. See SystemDefinition \"revision\" attribute.\n";
      $$node1->setAttribute('revision',$revision1." + ".$revision2);
    }
    else
    { # Files have different DTDs. Use attribute found in first file. report as ERROR!!
        print $GenXml::gLogFileH "ERROR: Source file schema/revison attributes conflict. Merged file will probably not be usable.\n";
        if ($schema1)
        { # First file had new DTD and had a schema attribute
          $$node1->setAttribute('schema',$schema1);
        }
        elsif ($revision1)
        { # First file had old DTD and had a revision attribute (not a schema)
          $$node1->setAttribute('revision',$revision1);
        }
    }
  }
  
  # Get the children of the parent nodes

  my $nodelist1 = $$node1->getChildNodes;    
  my $nodelist2 = $$node2->getChildNodes;    

  # Useful debug stuff
  #print "has ".$nodelist2->getLength." children\n";
  
  # Itterate throught the children of node2 check to see if they are present / rule match in node 1
  my $ni = $nodelist2->getLength;
  for (my $i = 0; $i < $ni; $i++)
  {
    # Useful debug stuff
    #print "node $i ".$nodelist2->item($i)->getNodeTypeName."\n";
    if ($nodelist2->item($i)->getNodeTypeName eq "ELEMENT_NODE")
    {
      # Handle rule match on ELEMENTS
      my $tagname2 = $nodelist2->item($i)->getTagName;
      
      # Useful debug stuff
      # print "Tagname = $tagname\n";
      if (($tagname2 eq "systemModel") || ($tagname2 eq "build") )
      {
        my $iBuildIndx;
        # find the $node1 for this elements
        my $nj = $nodelist1->getLength;
        my $match = 0;
        for (my $j = 0; $j < $nj; $j++)
        {
          if ($nodelist1->item($j)->getNodeTypeName eq "ELEMENT_NODE")
          {
            my $tagname1 = $nodelist1->item($j)->getTagName;
            if ($tagname1 eq $tagname2)
            {
              # process further
              
              # Useful debug stuff
              #print "processing $tagname further\n";
              &process_node(\($nodelist1->item($j)), \($nodelist2->item($i)), $doc1);
              $match = 1;
            }
            else
            {
              if ($tagname1 eq 'build')
              {
                $iBuildIndx = $j;
              }
              if ((($tagname2 eq 'systemModel') and ($tagname1 ne 'systemModel')) or ((($tagname2 eq 'build') and ($tagname1 ne 'build'))))
              {
                next;
              }
              # no systemModel or build element found so append child
              &append_child($node1, \($nodelist2->item($i)), $doc1)
            }
          }
        }
        unless ($match)
        {
          # no systemModel or build element found so append child
          # In the special case of adding an instance of 'systemModel' we must specify that this goes before any instance of 'build'
          my $iRefChildRef = ($tagname2 eq 'systemModel')? $nodelist1->item($iBuildIndx): undef;
          &append_child($node1, \($nodelist2->item($i)), $doc1, $iRefChildRef);
        }
      } elsif (($tagname2 eq "layer") || ($tagname2 eq "logicalset") || ($tagname2 eq "logicalsubset") || ($tagname2 eq "module") || ($tagname2 eq "component") || ($tagname2 eq "package") || ($tagname2 eq "unitList"))
      {
        # Check the $node1 for elements with the same "name"
        my $match; # Flag for matching element found
        my $nj = $nodelist1->getLength;
        for (my $j = 0; $j < $nj; $j++)
        {
          # Only look at element nodes in node1
          if ($nodelist1->item($j)->getNodeTypeName eq "ELEMENT_NODE")
          {
            if ($nodelist2->item($i)->getAttribute('name') eq $nodelist1->item($j)->getAttribute('name'))
            {
              # Process further match found
              $match = 1;
              
              # Useful debug stuff
              #print "processing j=$j $tagname2 further ".$nodelist2->item($i)->getAttribute('name')."\n";
              
              &process_node(\($nodelist1->item($j)), \($nodelist2->item($i)), $doc1);
            }
          }
        }
        # If no match found Append child
        
        # Useful debug stuff
        #print "new $tagname2 added\n" if (!$match);
        
        &append_child($node1, \($nodelist2->item($i)), $doc1) if (!$match);
        
      } elsif (($tagname2 eq "unit") || ($tagname2 eq "targetList") || ($tagname2 eq "target") || ($tagname2 eq "option") || ($tagname2 eq "configuration")) {
        # Check the $node1 for elements with the same ID attribute (Global check for ID clashes)
        my $idAttrib;
        if ($tagname2 eq "unit")
        {
          # Special case of the unit element as this has uses the attribute of unitID instead of name
          $idAttrib = "unitID";
        } else {
          $idAttrib = "name";
        }
        
        my $ID = $nodelist2->item($i)->getAttribute($idAttrib);
        # Search for the XML ID in $doc1
        if( scalar(XML::XQL::solve ("//*[\@$idAttrib = '$ID']", $$doc1)))
        {
          print $GenXml::gLogFileH "REMARK: $ID already exists, not merging this $tagname2 element\n";
        } else {
          # unitID not found so append elememnt
          
          # Useful debug stuff
          # print "new $tagname2 added\n";
          
          &append_child($node1, \($nodelist2->item($i)), $doc1);
        }
      } elsif ($tagname2 eq "unitRef") {
        # Check the $node1 for elements with the same "name"
        my $match; # Flag for matching element found
        my $nj = $nodelist1->getLength;
        for (my $j = 0; $j < $nj; $j++)
        {
          # Only look at element nodes in node1
          if ($nodelist1->item($j)->getNodeTypeName eq "ELEMENT_NODE")
          {
            if ($nodelist2->item($i)->getAttribute('unit') eq $nodelist1->item($j)->getAttribute('unit'))
            {
              # Ignore the unitRef element as it is a duplicate
              $match = 1;
              print $GenXml::gLogFileH "WARNING: Duplicate unitRef ".$nodelist2->item($i)->getAttribute('unit')." not merging\n";
            }
          }
        }
        # No match found Append Child
        
        # Useful debug stuff
        # print "New unitRef\n" if (!$match);
        
        &append_child($node1, \($nodelist2->item($i)), $doc1) if (!$match);
        
      } else {
        # Element not recognised so append child
        &append_child($node1, \($nodelist2->item($i)), $doc1);
      }
    } else {
      # Handle non element nodes (append child of node2 to node 1)
      # At the moment adding in non element nodes adds a lot of whitespace
      # TODO: correctly handle non element nodes
      # This is not important at the moment as there are no important non element nodes for the merge
      #&append_child($node1, \($nodelist2->item($i)), $doc1);
    }
  }
  
  #print "return $GenXml::count\n";
  #$GenXml::count--;
}

# append_child
#
# Inputs
# $node1 - is already a ref of the node to append to
# $node2 - ref of node from nodelist2 to append to $node1
# $doc1 - ref to document to merge the node into (need for non DOM operation of changing owner of node)
# $refnode - ref to node in fromt of which to insert node2 (If undef, append node2)
#
# Description
# ???
sub append_child
{
  my ($node1, $node2, $doc1, $refnode) = @_;
  
  # Clone the node
  my $clone = $$node2->cloneNode(1); 
  # Fix the owner of node
  $clone->setOwnerDocument($$doc1);
  # Append a line return for more tidy xml
  $$node1->addText("\n");
  # Append (or insert) the node
  # Note: it seems that insertBefore($clone,undef) is identical to appendChild($clone)
  $$node1->insertBefore($clone,$refnode);
}

# write_component_list
#
# Inputs
# $doc         - Reference to input document
# $iTextOutput - Name of output file
# $iConfName   - Name of configuration being described
# $bldList     - Reference to the bldList array
# $options     - Reference to the options array
# $tasks       - Reference to the tasks array
# $iEffectiveDir  - Root of source tree in which file will be used
# $iVersion - Version of xml file (new or old) ?
#
# Description:
# Write out old-style "list of components" build description for the configuration
#
sub write_component_list
	{
	my ($doc, $iTextOutput, $iConfName, $bldList, $options, $tasks, $iEffectiveDir, $iVersion) = @_;

	# process list of tasks to find build targets and bootstrap info	
	my %targets;
	my $bootflag = 0;
	
	foreach my $task (@$tasks)
		{
		# Read all the task 
		my @children = $task->getChildNodes;
		foreach my $child (@children)
			{
			next if ($child->getNodeTypeName ne "ELEMENT_NODE");
			if ($child->getTagName eq "specialInstructions")
				{
				# "setupprj" in the command is taken to mean "bootstrap E32ToolP"
				$bootflag = 1 if ($child->getAttribute("command") =~ /setupprj/i);
				next;
				}			
	        my $targetlist = $child->getAttributeNode("targetList");
	        if (defined $targetlist)
				{
				my @targetnames = &find_targetList_by_ID($doc, $targetlist->getValue);
				foreach my $target (@targetnames)
					{
					$targets{$target}= 1;
					}
				}
	        } 
	    }
		
	# create output file
	open TEXTFILE, "> $iTextOutput" or die "ERROR: RealTimeBuild: Couldn't open $iTextOutput for writing: $!\n";

    print TEXTFILE <<HEADER_TXT;
#
# ****************************** IMPORTANT NOTE ************************************
#
# The configuration was specified as: $iConfName
#
# **********************************************************************************
#

HEADER_TXT

    print TEXTFILE "# Optional variations in the generated scripts\n\n";

    my $column2pos = 8;
    foreach my $option (@$options)	{
	my $name = '<option ????>';
	if ($option =~ /^-(.+)/) {$name = "<option $1>"}
	my $len = length $name;
	while ($len > $column2pos) { $column2pos += 8; }
	printf TEXTFILE "%-*s\t# use abld %s\n", $column2pos, $name, $option;
    }
    
    $column2pos = 8;
    foreach my $target (sort keys %targets)	{
	# abld targets are only one word
	next if ($target =~ /\w+\s+\w+/);
	my $name;
	if ($target =~ /(misa|mint|mcot|mtemplate|meig)/i)		{
		$name = "<option arm_assp $target>";
	} else {
		$name = "<option $target>";
	}
	my $len = length $name;
	while ($len > $column2pos) { $column2pos += 8; }
	printf TEXTFILE "%-*s\t#\n", $column2pos, $name;
    }
	
    print TEXTFILE "\n";
    print TEXTFILE "# List of components required \n";
    print TEXTFILE "#\n# Name		abld_directory\n";

    if($bootflag)	{
        print TEXTFILE "#\n# Bootstrapping....\n\n";
        print TEXTFILE "<special bldfiles E32Toolp group>			# Special installation for E32ToolP\n\n";
        print TEXTFILE "# Components:\n";
    }
    print TEXTFILE "#\n";
    
    
    my $srcprefix = quotemeta($iEffectiveDir);
    
    $column2pos = 8;
    foreach my $component (@$bldList)		{
	my $bldinfdir = $component->[1];
	next if ($bldinfdir eq "");	# skip MRP-only entries
	
	$bldinfdir =~ s/^$srcprefix//o;
	my $len = length $component->[0];
	while ($len > $column2pos) { $column2pos += 8; }
	printf TEXTFILE "%-*s\t%s\n", $column2pos, $component->[0], $bldinfdir;
    }
    close TEXTFILE	
}

# write_CBR_list
#
# Inputs
# $iCBROutput  - Name of output file
# $bldList     - Reference to the bldList array
#
# Description:
# Write out "list of CBR components" for the configuration
#
sub write_CBR_list
	{
	my ($iCBROutput, $bldList) = @_;

	my @components = ();
	foreach my $component (@$bldList)
		{
		my $mrp = $component->[2];
		next if ($mrp eq "");	# skip entries without MRP files
		
		push @components, sprintf("%s\t%s\n", $component->[0], $mrp);
		}
	
	# create output file
	open TEXTFILE, "> $iCBROutput" or die "ERROR: RealTimeBuild: Couldn't open $iCBROutput for writing: $!\n";
	print TEXTFILE sort @components;
	close TEXTFILE	
	}

# start_output_doc
#
# Inputs
# $iConfName - Configuration name used
# $iVersion - Version of xml file (new or old) ?
#
# Outputs
# $outDoc - document
# $docElem - root element
# $commands - command node
#
# Description
# This function produces the static parts of the output XML file
sub start_output_doc
{
  my ($iConfName, $iVersion) = @_;
  
  my ($outParser, $outDoc, $docElem, $commands);
  
  # set the doctype based on which version of file is passed.  
  my $doctype;
  if ($iVersion == 1)	{
	$doctype = "Build";
  } elsif ($iVersion == 2)	{
	$doctype = "SystemBuild" ;
  }

  $outParser = new XML::DOM::Parser;

  my $str = <<END;
<?xml version="1.0"?>
<!DOCTYPE $doctype  [
  <!ELEMENT Product (Commands)>
  <!ATTLIST Product name CDATA #REQUIRED>
  <!ELEMENT Commands (Execute+ | SetEnv*)>
  <!ELEMENT Execute EMPTY>
  <!ATTLIST Execute
  ID CDATA #REQUIRED
  Stage CDATA #REQUIRED
  Component CDATA #REQUIRED
  Cwd CDATA #REQUIRED
  CommandLine CDATA #REQUIRED>
  <!ELEMENT SetEnv EMPTY>
  <!ATTLIST SetEnv
  Order ID #REQUIRED
  Name CDATA #REQUIRED
  Value CDATA #REQUIRED>
]>
<Product>
</Product>
END

  $outDoc = $outParser->parse($str);
  
  # get the document element
  $docElem = $outDoc->getDocumentElement;
  $docElem->setAttribute('name', $iConfName);
  # Add the Commands Node
  $commands = $outDoc->createElement('Commands');
  $commands->addText("\n");
  # create the default SetEnv elements
  my $SetEnv1 = $outDoc->createElement('SetEnv');
  $SetEnv1->setAttribute('Order', '1');
  $SetEnv1->setAttribute('Name', 'EPOCROOT');
  $SetEnv1->setAttribute('Value', '\\');
  $commands->appendChild($SetEnv1);
  $commands->addText("\n");
  my $SetEnv2 = $outDoc->createElement('SetEnv');
  $SetEnv2->setAttribute('Order', '2');
  $SetEnv2->setAttribute('Name', 'PATH');
  $SetEnv2->setAttribute('Value', '\\epoc32\\gcc\\bin;\\epoc32\\tools;%PATH%');
  $commands->appendChild($SetEnv2);
  $commands->addText("\n");
  
  return ($outDoc, $docElem, $commands);
}

# process_prebuilt
#
# Inputs
# $outDoc - Reference to output document
# $commands - Reference to the command node
# $ID - Reference to theExecute ID counter
# $Stage - Reference to the Execute Stage counter
# $topunits - Reference to the list of unit, package & prebuilt elements
# $late - Selects on the "late" attribute of prebuilt elements   
# $iVersion - Version of xml file (new or old) ?
#
# Outputs
#
# Description
# Generates the "getrel" commands for prebuilt elements
sub process_prebuilt
{
  my ($outDoc, $commands, $ID, $Stage, $topunits, $late, $iVersion) = @_;
  
  my ($name, $version, $islate);
  foreach my $unit (@$topunits)
  	{
	my @prebuilt;	# a list of all <prebuilt> or <unit prebuilt="...">
	if ($iVersion == 1)	{
		if ($unit->getTagName eq "prebuilt")
			{
			push(@prebuilt, $unit);
			}
	} elsif ($iVersion == 2)	{
		my @subunits = $unit->getElementsByTagName("unit");
		foreach my $subunit (@subunits)
			{
			if ($subunit->getAttribute("prebuilt"))
				{
				push(@prebuilt, $subunit);
				}
			}
	}
	  foreach my $unit (@prebuilt)
	  	{
		$version = $unit->getAttribute("version");
		$islate = $unit->getAttribute("late");
		$name = $unit->getAttribute(($iVersion == 1) ? "name" : "prebuilt");
	  	
		$islate = "N" if (!defined $islate || $islate eq "");
		
		next if ($late ne $islate);
		next if (!$late && $islate eq "Y");

		# Create the element
		my $task_elem = $$outDoc->createElement('Execute');
		$task_elem->setAttribute('ID', $$ID);
		$$ID++; # The ID must always be incremented
		$task_elem->setAttribute('Stage', $$Stage);
		$$Stage++;	# getrel operations are serial
		
		$task_elem->setAttribute('Component',$name);
		$task_elem->setAttribute('Cwd','%EPOCROOT%');
		$task_elem->setAttribute('CommandLine',"getrel $name $version");
		
		$$commands->appendChild($task_elem);
		$$commands->addText("\n");
	    }
	 }
}

# process_task
#
# Inputs
# $task - task node
# $doc - Reference to input document
# $outDoc - Reference to output document
# $commands - Reference to the command node
# $ID - Reference to theExecute ID counter
# $Stage - Reference to the Execute Stage counter
# $bldList - Reference to the bldList array
# $options - Reference to the options array
# $iSourceDir - root of the current source tree
# $iEffectiveDir - root from which the source tree will be used
# $iVersion - Version of xml file (new or old) ?
#
# Outputs
#
# Description
# This function processes the task nodes
sub process_task
{
  my ($task, $doc, $outDoc, $commands, $ID, $Stage, $bldList, $options, $iSourceDir, $iEffectiveDir, $iVersion) = @_;
  
  my @targets;
  my @localBldList; # Used for task specific unit list overrides
  
  # re-process the $iSourceDir & $iSourceDir based on version of xml file along with value for unitListRef and unitList
  my ($unitListRef, $unitList);
  if($iVersion == 1)	{
	$unitListRef = "unitListRef";
	$unitList = "unitList";
  } elsif ($iVersion == 2)	{
	$unitListRef = "listRef";
	$unitList = "list";
  }

  # Read all the task 
  my @children = $task->getChildNodes;
  foreach my $child (@children)
  {
    if ($child->getNodeTypeName eq "ELEMENT_NODE")
    {
      # Check for unitListRef for task unit list override
      if ($child->getTagName eq $unitListRef)
      {
        #Processes the unitListRefs to build up a complete list of units which are IDREFs
        my @localUnits= &find_unitList_by_ID($doc, $child->getAttribute($unitList), $iVersion);
        push @localBldList, &compute_bldList($iSourceDir,$iEffectiveDir,\@localUnits, $iVersion);
        # Overwrite Ref $bldList with new Ref to @localBldList
        $bldList = \@localBldList;
      }
      
      if ($child->getTagName eq "specialInstructions")
      {
        #Processes the unitListRefs to build up a complete list of units which are IDREFs
        my $task_elem = $$outDoc->createElement('Execute');
        $task_elem->setAttribute('ID', $$ID);
        $$ID++; # The ID must always be incremented
        $task_elem->setAttribute('Stage', $$Stage);
        $$Stage++; # All specialInstructions are done sequentially
        $task_elem->setAttribute('Component', $child->getAttributeNode("name")->getValue);
        my ($cwd) = $child->getAttributeNode("cwd")->getValue;
        # Replace any Environment variables
        my ($cwdtemp) = $cwd;
        $cwdtemp =~ s/%(\w+)%/$ENV{$1}/g;
        # If $cwd does not starts with a drive letter or absolute path then add the source Directory on the front
        if (!(($cwdtemp =~ /^\w:[\\]/) || ($cwdtemp =~ /^\\/)))
        {
          $cwd = $iEffectiveDir . $cwd;
        }
        $task_elem->setAttribute('Cwd', $cwd);
        $task_elem->setAttribute('CommandLine', $child->getAttributeNode("command")->getValue);
        $$commands->appendChild($task_elem);
        $$commands->addText("\n");
      } elsif ($child->getTagName eq "buildLayer") {
        # targetParallel & unitParallel are optional so check that they exist before trying to get the value.
        my $unitP = $child->getAttribute("unitParallel");
        my $targetP = $child->getAttribute("targetParallel") if ($child->getAttributeNode("targetParallel"));
        my $abldCommand = $child->getAttribute("command");
        
        # Build the list of targets, targets are optional
        if ($child->getAttributeNode("targetList"))
        {
          @targets = &find_targetList_by_ID($doc, $child->getAttributeNode("targetList")->getValue);
        } else {
          # There are no targets associated with this buildlayer
          $targetP = "NA"; # Not applicable
        }
        
        # Build the correct option string
        my $optionStr = "";
        foreach my $option (@$options)
        {
          # only add -savespace if the command abld target or abld build take this option
          # don't add -keepgoing if -what or -check are part of the command
          if ((($option =~ /\s*-savespace\s*/i) || ($option =~ /\s*-s\s*/i) ) && (($abldCommand =~ /^\s*abld\s+makefile/i) || ($abldCommand =~ /^\s*abld\s+target/i) || ($abldCommand =~ /^\s*abld\s+build/i)))
          {
            $optionStr .= " $option" ;
          }
          if (($option =~ /\s*-keepgoing\s*/i) || ($option =~ /\s*-k\s*/i) )
          {
            if (!(($abldCommand =~ /^\s*abld\s+\w*\s*\w*\s*-check\s*/i) || ($abldCommand =~ /^\s*abld\s+\w*\s*\w*\s*-c\s*/i) || ($abldCommand =~ /^\s*abld\s+\w*\s*\w*\s*-what\s*/i) || ($abldCommand =~ /^\s*abld\s+\w*\s*\w*\s*-w\s*/i)))
            {
              $optionStr .= " $option" ;
            }
          }
            # This allows us to either build symbol files or not build symbols to save build time.          
            # only add -no_debug if the command abld makefile
            if (($option =~ /\s*-no_debug\s*/i) && ($abldCommand =~ /^\s*abld\s+makefile/i))
            {
              $optionStr .= " $option" ;
            }
        }
        
        # Remove the mrp-only entries from the bldList
        my @bldInfList;
        foreach my $array (@{$bldList})
          {
          push @bldInfList, $array if ($$array[1] ne "");
          }
        
        # Cover all the combinations of units and targets
        my ($Ref1, $Ref2, $loop1, $loop2);
        
        if ($targetP eq "N")
        {
          # Got to switch order of looping
          $Ref2 = \@bldInfList;
          $Ref1 = \@targets;
          $loop2 = $unitP;
          $loop1 = $targetP;
        } else {
          $Ref1 = \@bldInfList;
          $Ref2 = \@targets;
          $loop1 = $unitP;
          $loop2 = $targetP;
        }
        
        for (my $i = 0; $i < scalar(@$Ref1); $i++)
        {
          if ($targetP ne "NA")
          {
            for (my $j = 0; $j < scalar(@$Ref2); $j++)
            {
              # Create the element
              my $task_elem = $$outDoc->createElement('Execute');
              $task_elem->setAttribute('ID', $$ID);
              $$ID++; # The ID must always be incremented
              $task_elem->setAttribute('Stage', $$Stage);
              
              if ($targetP eq "N") {
                # loops swapped but the order of unitP and targetP need to be swapped back
                # unit (Component) name is the 0 element of the sub array, source location in element 1
                $task_elem->setAttribute('Component',$$Ref2[$j][0]);
                # Find the bldFile directory and set as Cwd
                $task_elem->setAttribute('Cwd',$$Ref2[$j][1]);
                
                $task_elem->setAttribute('CommandLine',$abldCommand.$optionStr." ".$$Ref1[$i]);
                $$commands->appendChild($task_elem);
                $$commands->addText("\n");
              } else {
                # unit (Component) name is the 0 element of the sub array, source location in element 1
                $task_elem->setAttribute('Component',$$Ref1[$i][0]);
                # Find the bldFile directory and set as Cwd
                $task_elem->setAttribute('Cwd',$$Ref1[$i][1]);
                
                $task_elem->setAttribute('CommandLine',$abldCommand.$optionStr." ".$$Ref2[$j]);
                $$commands->appendChild($task_elem);
                $$commands->addText("\n");
              }
              $$Stage++ if (($loop1 eq "N") && ($loop2 eq "N"));
            }
            $$Stage++ if (($loop1 eq "N") && ($loop2 eq "Y"));
          } else {
            # Create the element
            my $task_elem = $$outDoc->createElement('Execute');
            $task_elem->setAttribute('ID', $$ID);
            $$ID++; # The ID must always be incremented
            $task_elem->setAttribute('Stage', $$Stage);

            # unit (Component) name is the 0 element of the sub array, source location in element 1
            $task_elem->setAttribute('Component',$$Ref1[$i][0]);
            # Find the bldFile directory and set as Cwd
            $task_elem->setAttribute('Cwd',$$Ref1[$i][1]);
            
            $task_elem->setAttribute('CommandLine',$abldCommand.$optionStr);
            $$commands->appendChild($task_elem);
            $$commands->addText("\n");

            $$Stage++ if ($loop1 ne "Y");
          }
        }
        # Add the * (stage++) for the combinations that don't get this done by the loops
        $$Stage++ if ($loop1 eq "Y");
      }
    }
  }
}

# delete_unmatched_units
#
# Inputs
# $node - node in the system model
# $deletedref - reference to hash of deleted unitIDs
#
# Outputs
# Returns 1 if all significant children of the node have been removed
#
# Description
# This function simplifies the XML by removing anything which wasn't marked as MATCHED.
# It's called recursively so that it can "clean up" the structure if whole subtrees have
# all of their significant content removed. 
sub delete_unmatched_units
	{
	my ($node, $deletedUnitsRef) = @_;
	my @children = $node->getChildNodes;
	return 0 if (scalar @children == 0);
	my $now_empty = 1;
	my $deleted_something = 0;
	foreach my $child (@children)
		{
		if ($child->getNodeTypeName ne "ELEMENT_NODE")
			{
			# text and comments don't count
			next;
			}
		my $tag = $child->getTagName;
		my $deletedThis = 0;
		if ((($tag eq "unit" || $tag eq "package" || $tag eq "prebuilt") && $iVer == 1) || (($tag eq "component" || $tag eq "unit") && $iVer == 2))
			{
			# only units,prebuilts & packages are tagged
			if (!$child->getAttribute("MATCHED"))
				{
				if ($tag eq "unit")
					{
					my $unitID = $child->getAttribute("unitID");
					$$deletedUnitsRef{$unitID} = 1;
					}
				if($tag eq "unit" && $iVer == 2)
					{
					my $version = $child->getAttribute("version");
					printf $GenXml::gLogFileH "Simplification removed $tag %s %s\n", ($version eq '') ? 'from' : "v$version of" ,$node->getAttribute("name"); 
					}
				else
					{
					printf $GenXml::gLogFileH "Simplification removed $tag %s\n", $child->getAttribute("name"); 
					}
				$node->removeChild($child);
				$deletedThis = 1;
				$deleted_something = 1;
				}
			else
				{
				$child->removeAttribute("MATCHED");
				$now_empty = 0;		# something left in due to this child
				}
			}
		# keep going to filter child units
		if (!$deletedThis && $tag ne "unit" && $tag ne "package" && $tag ne "prebuilt")
			{
			if (delete_unmatched_units($child,$deletedUnitsRef) == 1)
				{
				# Child was empty and can be removed
				$node->removeChild($child);
				$deleted_something = 1;
				}
			else
				{
				$now_empty = 0;		# something left in due to this child
				}
			}
		}
	return 0 unless ($deleted_something);
	return $now_empty;
	}


# Filter_doc
#
# Inputs
# $doc - Reference to input document
# $iFilter - filter to apply
#
# Outputs
#
# Description
# This function simplifies the XML by removing anything which fails to pass the filter.
# The resulting doc is then useful for tools which don't understand the filter attributes.
sub Filter_doc
	{
	my ($doc, $iFilter) = @_;
	  
	# the filtering will have to be
	# - find the configurations which pass the filter (and delete the rest)
	# - identify items which are kept by some configuration
	# - remove the ones which aren't kept by any configuration.

	# deal with the <configuration> items, checking their filters
	my %unitLists;
	my @nodes = $doc->getElementsByTagName ("configuration");
	foreach my $node (@nodes)
		{
		my $configname = $node->getAttribute("name");
		my @configspec = split /,/,$node->getAttribute("filter");
		my $failed = check_filter($iFilter,\@configspec);
		if ($failed ne "")
			{
			print $GenXml::gLogFileH "Simplification removed configuration $configname ($failed)\n";
			$node->getParentNode->removeChild($node);
			next;
			}
		# find all the units for this configuration and mark them as MATCHED
		print $GenXml::gLogFileH "Analysing configuration $configname...\n";
  		my $units = get_configuration_units($doc, $node, 0, 0);
  		foreach my $unit (@$units)
  			{
  			$unit->setAttribute("MATCHED", 1);
  			}
  		# note all the unitLists referenced by this configuration
  		foreach my $unitListRef ($node->getElementsByTagName("unitListRef"))
  			{
  			my $unitList = $unitListRef->getAttribute("unitList");
  			$unitLists{$unitList} = 1;
  			} 		
		}
	# walk the model, removing the "MATCHED" attribute and deleting any which weren't marked
	my %deletedUnits;
	delete_unmatched_units($doc, \%deletedUnits);
	
	# clean up the unitlists
	my @unitLists = $doc->getElementsByTagName("unitList");
	foreach my $unitList (@unitLists)
		{
		my $name = $unitList->getAttribute("name");
		if (!defined $unitLists{$name})
			{
			print $GenXml::gLogFileH "Simplification removed unitList $name\n";
			$unitList->getParentNode->removeChild($unitList);
			next;
			}
		foreach my $unitRef ($unitList->getElementsByTagName("unitRef"))
			{
			my $id = $unitRef->getAttribute("unit");
			if (defined $deletedUnits{$id})
				{
				$unitList->removeChild($unitRef);	# reference to deleted unit
				}
			}
		}

	}

# find_configuration
#
# Inputs
# $doc - DOM document model
# $iConfName - configuration name
#
# Outputs
# $configuration - the node of the named configuration
#
# Description
# This function locates and returns the named configuration node
sub find_configuration
{
  my ($doc, $iConfName) = @_;
  
  # Find the named configuration 
  my @nodes = $doc->getElementsByTagName ("configuration");
  foreach my $node (@nodes)
  {
      my $name = $node->getAttributeNode ("name");
      if ($name->getValue eq $iConfName)
      {
        return $node;
      }
  }
  
  # If no configuration has been found the produce ERROR message
  die "ERROR: RealTimeBuild: Named configuration $iConfName not found\n";
}

# process_configuration
#
# Inputs
# $doc - DOM document model
# $iConfName - name of the configuration
# $iVersion - Version of xml file (new or old) ?
#
# Outputs
# $topunits - reference to a list of units in the main configuration
# $subunits - reference to a list of local units contained within subtasks
# \@options - reference to a list of options which apply (curently global options)
# \@tasks   - reference to a list of the task nodes for the configuration
#
# Description
# This function locates the named configuration and processes it into
# a list of units, the build options which apply, and the task elements in
# the configuration.
sub process_configuration
{
  my ($doc, $iConfName, $iVersion) = @_;

  my @options; # list of global options
  my @units; # list of individual buildable items

  # NB. getElementsByTagName in list context returns a list, so
  # the following statement gets only the first element of the list
  my ($build, @nodes); 
  if ($iVersion == 1)	{
    $build = $doc->getElementsByTagName("build");
  } else {
    $build = $doc->getElementsByTagName("SystemBuild");
  }
  
  @nodes = $build->[0]->getElementsByTagName("option");

  # Read the global options (savespace and keepgoing)
  foreach my $node (@nodes)
  {
    my $name = $node->getAttributeNode("abldOption");
    my $enable = $node->getAttributeNode("enable")->getValue;
    push @options, $name->getValue if ($enable =~ /Y/i);
  }

  # Find named configuration
  my $configuration = find_configuration($doc, $iConfName);  

  # Get the list of tasks
  my @tasks = $configuration->getElementsByTagName("task");
  
  my ($topunits, $subunits);
  # Get the filtered list of units
  if ($iVersion == 1)	{
    $topunits = get_configuration_units($doc, $configuration, 1, 1);
    $subunits = get_configuration_units($doc, $configuration, 1, 2);
  } elsif ($iVersion == 2)	{
    $topunits = get_configuration_units2($doc, $configuration, 1, 1);
	
    $subunits = get_configuration_units2($doc, $configuration, 1, 2);
  }

  return ($topunits, $subunits,\@options,\@tasks);
  }

# check_filter
#
# Inputs
# $item_filter - filter specification (comma-separated list of words)
# $configspec - configuration specification (reference to list of words)
#
# Outputs
# $failed - filter item which did not agree with the configuration (if any)
#           An empty string is returned if the configspec passed the filter
#
# Description
# This function checks the configspec list of words against the words in the
# filter. If a word is present in the filter, then it must also be present in
# the configspec. If "!word" is present in the filter, then "word" must not
# be present in the configspec.
sub check_filter($$)	{
	my ($item_filter, $configspec) = @_;
	my $failed = "";
	foreach my $word (split /,/,$item_filter)    	{
		if ($word =~ /^!/)        	{
			# word must NOT be present in configuration filter list
			my $notword = substr $word, 1;
			$failed = $word if grep(/^$notword$/, @$configspec);
		} 
		else         	{
			# word must be present in configuration filter list
			$failed = $word unless grep(/^$word$/, @$configspec);
		}
	}
	return $failed;
}
	
# get_configuration_units
#
# Inputs
# $doc - DOM document model
# $configuration - configuration node
# $verbose - enable/disable logging
# $level - 0 = all units, 1 = top-level units, 2 = local units within tasks
#
# Outputs
# \@units - reference to a list of unit,package & prebuilt nodes which implement this configuration
#
# Description
# This function processes the specified configuration to get the list of unit or package
# nodes that implement this configuration.
sub get_configuration_units ($$$$)
{
    my ($doc, $configuration, $verbose, $level) = @_;
    my @units; # list of individual buildable items
  
    my ($model) = $doc->getElementsByTagName("SystemDefinition");
  
    # Start with the units specified via unitListRefs, then append the
    # units specified via layerRefs - they will be sorted afterwards anyway

    my @unitlistrefs = $configuration->getElementsByTagName("unitListRef");
    foreach my $child (@unitlistrefs)	{
	my $issublevel = $child->getParentNode->getTagName ne "configuration";
	next if (($level==1 && $issublevel) || ($level==2 && !$issublevel));
	push @units, &find_unitList_by_ID($doc, $child->getAttribute("unitList"), 1);
    }
    my @layerrefs = $configuration->getElementsByTagName("layerRef");
    foreach my $child (@layerrefs)		{
	my $issublevel = $child->getParentNode->getTagName ne "configuration";
	next if (($level==1 && $issublevel) || ($level==2 && !$issublevel));	
	my $layerName = $child->getAttribute("layerName");
	# Find the named object and enumerate the units it contains
	my ($layer) = XML::XQL::solve("//*[\@name = '$layerName']", $model);
	if (!defined($layer))		{
	  print $GenXml::gLogFileH "ERROR: no match for \"$layerName\"\n";
	  next;
	}
	my @newunits = $layer->getElementsByTagName("unit",1);
	my @newpackages = $layer->getElementsByTagName("package",1);
	my @newprebuilts = $layer->getElementsByTagName("prebuilt",1);
	if ($verbose)	{
	  printf $GenXml::gLogFileH "Layer \"$layerName\" contained %d units, %d packages and %d prebuilt\n",
		scalar @newunits, scalar @newpackages, scalar @newprebuilts;
	}
	push @newunits, @newpackages, @newprebuilts;
	if (scalar @newunits == 0)	{
	  print $GenXml::gLogFileH "WARNING: layerRef $layerName contains no units\n";
	}
	push @units, @newunits;
    }
    
    my @configspec = split /,/,$configuration->getAttribute("filter");
    my @filtered_units;
    
    # Scan the list, eliminating duplicates and elements which fail the filtering
    my %mrpfiles;
    foreach my $element (@units)	{
	my $name = $element->getAttribute("name");
	my $filter = $element->getAttribute("filter");
	
	if ($filter)	{
	  my $failed = &check_filter($filter,\@configspec);
	  if ($failed ne "")	{
	    print $GenXml::gLogFileH "Filtered out $name ($failed)\n" if ($verbose);
	    next;
	  }
        }
    
        my $mrp = $element->getAttribute("mrp");
	if ($mrp)	{
		my $unitID = $element->getAttribute("unitID");
		if (defined($mrpfiles{$mrp}))	{
		  # eliminate duplicates
		  next if ($mrpfiles{$mrp} eq $unitID);	
		  # report (and eliminate) conflicts
		  printf $GenXml::gLogFileH "WARNING: $mrp exists in %s and %s - skipping $unitID\n",  $unitID, $mrpfiles{$mrp};
		  next;
		}
		$mrpfiles{$mrp} = $unitID;
	}
	push @filtered_units, $element;
    }
    
    if ($verbose)	{
	printf $GenXml::gLogFileH "%s contains %d units at level %d\n", 
			$configuration->getAttribute("name"), scalar @filtered_units, $level;
    }
    return \@filtered_units;
}

# compute_bldList
#
# Inputs
# $iSourceDir - root of the current source tree
# $iEffectiveDir - root of the source tree when used
# $elements - reference to list of units, packages & prebuilts which can be part of the configuration
# $iVersion - Version of xml file (new or old) ?
#
# Outputs
# @bldList - a list of [name, bld.inf_dir, mrpfile] arrays, using $iEffectiveDir
#
# Description
# This function processes a list of unit and package elements, extracting from
# them the location of the associated bld.inf files. If bld.inf_dir is "" then
# no bld.inf was specified (e.g. a package) or the bld.inf file does not exist.
# If mrpfile is "" then no mrp file was specified.
# <prebuilt> elements return "*nosource*" as the mrpfile
sub compute_bldList
{
  my ($iSourceDir, $iEffectiveDir, $elements, $iVersion) = @_;
  my @bldList;
  my %priorityLists;
  my ($name, $bldFile, $mrp, $priority, $unitID, $effmrp, $effbldFile, $packageName);
  my ($count, $unit, @childNodes, @unitNames);
  foreach my $element (@$elements)
  {
    # Variable holding the previous values and so giving wrong results.  Lets undefine them.
    undef $name; undef $bldFile; undef $mrp; undef $priority; undef $unitID; undef $effmrp; undef $effbldFile;
    if ($iVersion == 1)	{
      push(@childNodes,$element);
    } elsif ($iVersion == 2)	{
      my @units = $element->getElementsByTagName("unit");
      for ( @units )
      {
        push(@childNodes, $_);
        push(@unitNames, $element->getElementsByTagName("name"));
      }
    }
  }
  
  # should only be one childNodes, but this will make sure we handle all in case there are any
  for my $index ( 0 .. $#childNodes )  	{
	my $unit = $childNodes[$index];
	my $unitName = $unitNames[$index];
   if ($iVersion == 1)	{
       $name = $unit->getAttribute("name");
       $bldFile = $unit->getAttribute("bldFile");
       $mrp = $unit->getAttribute("mrp");
       $priority = $unit->getAttribute("priority");
       $unitID = $unit->getAttribute("unitID");
       $effmrp = $mrp;
       $effbldFile = $bldFile;
   } elsif ($iVersion == 2)	{
       $name = $unitName;
       $bldFile = $unit->getAttribute("bldFile");
       $mrp = $unit->getAttribute("mrp");
       $priority = $unit->getAttribute("priority");
       $mrp =~ /.+\\([\w_-]+)\.mrp/;
       $packageName = $1;
       $effmrp = $mrp;
       $effbldFile = $bldFile;
       $unitID = $name;
   }
   
   if ($mrp)
   {
     if ($mrp !~ /^\\/)
       {
       # watch out for mrp="\product\..."
       $mrp = $iSourceDir.$mrp;
       $effmrp = $iEffectiveDir.$effmrp;
       }
     if (-f $mrp)
     {
       # get the component name
       open MRPFILE, "<$mrp"
         or print $GenXml::gLogFileH "ERROR: Cannot read $mrp - skipping \"$unitID\"\n" and next;
       my $mrpline;
       while ($mrpline = <MRPFILE>)
       {
         if ($mrpline =~ /^\s*component\s+(\S+)/)
         {
           $name = $1;
           last;
         }
       }
       close MRPFILE;
     } else {
       # print $GenXml::gLogFileH "ERROR: $mrp does not exist - skipping \"$unitID\"\n";
       # next;
       $name = $packageName if defined $packageName;
       # Unfortunately, we need to cope with the pkgdefs components which are created later
       print $GenXml::gLogFileH "REMARK: $mrp does not exist - assuming $name is correct...\n";
     }
   } else {
     $mrp = "";
     $effmrp = "";
   }
   if ($bldFile)
   {
     if ($bldFile =~ /^\w:\\/)
     {
       print "Warning:Bldfile path should not contain drive letters.The build may continue with problems\n";
     }
     else
     {
       if ($bldFile =~ /^\\/)
       {
         # No need to add the source dir path
       }
       else
       {
         $bldFile = $iSourceDir.$bldFile;
         $effbldFile = $iEffectiveDir.$effbldFile;   
       }
     }
     if (!-f "$bldFile\\BLD.INF")
     {
       print $GenXml::gLogFileH "ERROR: $bldFile\\BLD.INF does not exist - skipping \"$unitID\"\n";
       next;
     }
   } else {
     $bldFile = "";
     $effbldFile = "";
   }
   
   if ($mrp eq "" && $bldFile eq "")	    {
           if ($iVersion == 1)	    {
             if ($unit->getTagName eq "prebuilt")      {
               $mrp = "*nosource*";
               $effmrp = $mrp;
             } 
           } elsif ($iVersion == 2) {
             if ($unit->getAttribute("prebuilt")) 	{
                   $mrp = "*nosource*";
                   $effmrp = $mrp;
                   $name = $unit->getAttribute("prebuilt");
               }
           }
          }
    if($mrp eq "" && $bldFile eq "") {
       #print $GenXml::gLogFileH "ERROR: no MRP file, no BLD.INF directory - skipping \"$unitID\"\n";
       next;
   }
   
   if (!$priority)
   {
     $priority = 1000;
   }
   
   if (! defined($priorityLists{$priority}))
   {
     $priorityLists{$priority} = ();
   }
   push @{$priorityLists{$priority}}, [$name,$effbldFile,$effmrp];
 }
   
  # concatenate the lists in (ascending numerical) priority order
  foreach my $priority (sort {$a <=> $b} keys %priorityLists)
  {
    push @bldList, @{$priorityLists{$priority}};
  }
  
  return @bldList;
}

# find_unitList_by_ID
#
# Inputs
# $doc - DOM document model
# $id - the IDREF of the unitList
# $iVersion - Version of xml file (new or old) ?
#
# Outputs
# @units - a list of unit elements referenced in the specified unit list
#
# Description
# This function is used to convert a unitListRef into the corresponding
# list of units.
sub find_unitList_by_ID()
{
  my ($doc, $id, $iVersion) = @_;
  
  my (@units, @element); # List of units in unitList and elements
  my ($unitList, $unitRef, $attribute);
  if ($iVersion == 1)	{
	  $unitList = "unitList" ;
	  $unitRef = "unitRef";
	  $attribute = "unit";
	  @element = XML::XQL::solve("//unitList[\@name = '$id']", $doc);
  } elsif ($iVersion == 2)	{
	  $unitList = "list" ;
	  $unitRef = "ref";
	  $attribute = "item";
	  @element = XML::XQL::solve("//list[\@name = '$id']", $doc);
  }
  
  # Should only return one element because the Validating Parser will not allow multiple DTD ID's
  if (!($element[0]))
  {
    print $GenXml::gLogFileH "ERROR: Cannot find $unitList $id\n";
    die "ERROR: RealTimeBuild: Cannot find $unitList $id\n";
  } 
  my @unitRefs = $element[0]->getElementsByTagName("$unitRef",1);
  if (scalar @unitRefs == 0)
  {
    print $GenXml::gLogFileH "WARNING: $unitList $id contains no units\n";
  }
  foreach my $unitRef (@unitRefs)
  {
    my $unitID = $unitRef->getAttribute("$attribute");
    my (@element);
    if ($iVersion == 1)	{    
	    (@element) = XML::XQL::solve ("//unit[\@unitID = '$unitID']", $doc);
    } elsif ($iVersion == 2)	{
	    (@element) = XML::XQL::solve ("//component[\@name = '$unitID']", $doc);
    }
    if (!($element[0]))
    {
      print $GenXml::gLogFileH "ERROR: $unitList $id refers to non-existent $attribute $unitID, not building\n";
      next;
    }
    push @units,$element[0];
  }
  return @units;
}

# find_targetList_by_ID
#
# Inputs
# $doc - reference to DOM document model
# $id - value of the IDREFS to find (multiple whitespace ID's)
#
# Outputs
# @targets - a list of targets referenced in the specified targetList
#
# Description
# This function finds a list of units and full source location
sub find_targetList_by_ID
{
  my ($doc, $idrefs) = @_;
  
  my $n; # Number of Nodes
  my @targets; # List of units in targetList
  
  # Split on whitespace to get ID's from IDREFS
  my @ids = split(/\s+/, $idrefs);
  
  for (my $i = 0; $i < scalar(@ids); $i++)
  {
    my ($id) = $ids[$i];
    my (@element) = XML::XQL::solve("//targetList[\@name = '$id']", $doc);
    # Should only return one element because the Validating Parser will not allow multiple DTD ID's
    # target attrib is another IDREFS list of target
    if (!($element[0]))
    {
      print $GenXml::gLogFileH "ERROR: Cannot find targetList $id\n";
      die "ERROR: RealTimeBuild: Cannot find targetList $id\n";
    }
    my $targetIDREFS;
    if ($element[0])
    {
      $targetIDREFS = $element[0]->getAttributeNode("target")->getValue;
    } else {
      print $GenXml::gLogFileH "ERROR: Cannot find targetList of $id\n";
      die "ERROR: RealTimeBuild: Processing error\n";
    }
    
    # Split on whitespace to get ID's from IDREFS
    my @targetsID = split(/\s+/, $targetIDREFS);
    for (my $j = 0; $j < scalar(@targetsID); $j++)
    {
      my ($target) = $targetsID[$j];
      my (@target_element) = XML::XQL::solve("//target[\@name = '$target']", $doc);
      # Should only return one element because the Validating Parser will not allow multiple DTD ID's
      if ($target_element[0])
      {
        push @targets, $target_element[0]->getAttributeNode("abldTarget")->getValue;
      } else {
        print $GenXml::gLogFileH "ERROR: Cannot find target of $target\n";
        die "ERROR: RealTimeBuild: Processing error\n";
      }
    }
  }
  
  return @targets;
}

# logfileHeader
#
# Inputs
# $comp - string to place in the "component" section of the header
#
# Outputs
#
# Description
# This function print the log file header to te global logfile handle
sub logfileHeader
{
  my ($comp) = @_;
  
  if ($gEmbeddedLog)
  {
    print $GenXml::gLogFileH "*** $comp\n";
    return;
  }
  
  # Log file headers for each log file loading
  print $GenXml::gLogFileH "=== Genxml == $comp\n";

  print $GenXml::gLogFileH "-- Genxml\n";
  # Add the per command start timestamp
  print $GenXml::gLogFileH "++ Started at ".localtime()."\n";
  # Add the per command start HiRes timestamp if available
  if ($gHiResTimer == 1)
  {
    print $GenXml::gLogFileH "+++ HiRes Start ".Time::HiRes::time()."\n";
  } else {
    # Add the HiRes timer missing statement
    print $GenXml::gLogFileH "+++ HiRes Time Unavailable\n";
  }
  $GenXml::gLogFileH->flush;
}

# logfileFooter
#
# Inputs
#
# Outputs
#
# Description
# This function print the log file footer to the global logfile handle
sub logfileFooter
{
  return if ($gEmbeddedLog);
  
  # Add the per command end HiRes timestamp if available
  print $GenXml::gLogFileH "+++ HiRes End ".Time::HiRes::time()."\n" if ($gHiResTimer == 1);
  # Add the per command end timestamp
  print $GenXml::gLogFileH "++ Finished at ".localtime()."\n";
  $GenXml::gLogFileH->flush;
}


#####################################################################################
#
#							v2 api's for new SystemDefinition
#
#####################################################################################

# process_node2
#
# Inputs
# $node1 - ref to the master doc
# $node2 - ref to the slave doc
# $doc1 - ref to the merged doc so we can set the doc owner to the (not DOM spec) to get around WRONG_DOCUMENT_ERR restriction
#
# Outputs
#
# Description
# This function processes a node in two DOM documents, if any children match then it calls itself to process
# the children nodes further
sub process_node2
{
  my ($doc1, $doc2) = @_;
  
  my $merged = new XML::DOM::Parser;
  
  # Some nodes need special processing e.g. SystemDefinition
  # This is because there can only be a certain number of these nodes
  # child node / element rules outlined below, this rules are applied to the children of the node in question
 
  my ($node1, $node2);
  
  # All other nodes                 Append child
  
  # Useful debug stuff
  #$GenXml::count++;
  #print "enter $GenXml::count\n";
  
  # Handle the special case for the first call to this function with the node containing the SystemDefinition
  if (($$doc1->getDocumentElement->getTagName eq "SystemDefinition") 
	&& ($$doc2->getDocumentElement->getTagName eq "SystemBuild"))
  {
    # Process the DTD and merge
    my $dtd1 = $$doc1->getDoctype->toString;
    my $dtd2 = $$doc2->getDoctype->toString;
    my $mergeddtd = &Merge_dtd($dtd1, $dtd2);
    $mergeddtd .= $$doc1->getDocumentElement->toString;
    $merged = $merged->parse($mergeddtd);

    $node1 = \($merged->getElementsByTagName("SystemDefinition"));
    $node2 = \($$doc2->getElementsByTagName("SystemBuild"));
    
    my $tagname = $$node2->getTagName;
    for my $item ($$doc2->getChildNodes)	{
      if ($item->toString =~ /^\s*<$tagname .+>/isg)	{
	  &append_child($node1, \($item), \$merged);
	  last;
      }
    }
  }
  
  return $merged;
}

# Merge_dtd
sub Merge_dtd	{
  my ($doctype1, $doctype2) = @_;
  my $mergeddtd;
  
  # split them into an array of values
  my @doctypeValues1 = split '\n', $doctype1;
  my @doctypeValues2 = split '\n', $doctype2;
  my $elementNameToAdd;
  
  my $count = 1;
  for my $line (@doctypeValues2)	{
	  if ( $line =~ /<!ELEMENT (\w+) .+>/ )	{
		  $elementNameToAdd = $1;
		  last;
	  }
	  $count++;
  }
  splice @doctypeValues2, 0, $count-1;
  
  my $i; 
  for ($i=0; $#doctypeValues1; $i++)	{
	  last if ( $doctypeValues1[$i] =~ /<!ELEMENT SystemDefinition .+>/);
  }
  $doctypeValues1[$i] =~ s/(.+) \)>$/$1?, $elementNameToAdd? )>/;
  
  $#doctypeValues1 = $#doctypeValues1 -1;
  
  push @doctypeValues1, @doctypeValues2;
  
  unshift @doctypeValues1, '<?xml version="1.0" encoding="UTF-8"?>';
  $mergeddtd = join "\n", @doctypeValues1;
  
  return $mergeddtd;
}

	
# Filter_doc2
#
# Inputs
# $doc - Reference to input document
# $iFilter - filter to apply
#
# Outputs
#
# Description
# This function simplifies the XML by removing anything which fails to pass the filter.
# The resulting doc is then useful for tools which don't understand the filter attributes.
sub Filter_doc2	{
	my ($doc, $iFilter) = @_;
	  
	# the filtering will have to be
	# - find the configurations which pass the filter (and delete the rest)
	# - identify items which are kept by some configuration
	# - remove the ones which aren't kept by any configuration.

	# deal with the <configuration> items, checking their filters
	my %lists;
	my @nodes = $doc->getElementsByTagName ("configuration");
	foreach my $node (@nodes)		{
		my $configname = $node->getAttribute("name");
		my @configspec = split /,/,$node->getAttribute("filter");
		my $failed = check_filter($iFilter,\@configspec);
		if ($failed ne "")		{
			print $GenXml::gLogFileH "Simplification removed configuration $configname ($failed)\n";
			$node->getParentNode->removeChild($node);
			next;
			}
		# find all the units for this configuration and mark them as MATCHED
		print $GenXml::gLogFileH "Analysing configuration $configname...\n";
  		my $unfiltered_items = get_configuration_units2($doc, $node, 0, 0);     # Replace the arg 1 with 0 to put the debug off
  		foreach my $unit (@$unfiltered_items) 			{
  			$unit->setAttribute("MATCHED", 1);
  			}
  		# note all the lists referenced by this configuration
  		foreach my $listRef ($node->getElementsByTagName("listRef"))		{
  			my $list = $listRef->getAttribute("list");
  			$lists{$list} = 1;
  			} 		
		}
		
	# walk the model, removing the "MATCHED" attribute and deleting any which weren't marked
	my %deletedUnits;
	delete_unmatched_units($doc, \%deletedUnits);
	
	# clean up the lists
	my @lists = $doc->getElementsByTagName("list");
	foreach my $list (@lists)	{
		my $name = $list->getAttribute("name");
		if (!defined $lists{$name})		{
			print $GenXml::gLogFileH "Simplification removed list $name\n";
			$list->getParentNode->removeChild($list);
			next;
		}
		foreach my $ref ($list->getElementsByTagName("ref"))	{
			my $id = $ref->getAttribute("item");
			if (defined $deletedUnits{$id})		{
				$list->removeChild($ref);	# reference to deleted unit
			}
		}
	}

}

# get_configuration_units2
#
# Inputs
# $doc - DOM document model
# $configuration - configuration node
# $verbose - enable/disable logging
# $level - 0 = all units, 1 = top-level units, 2 = local units within tasks
#
# Outputs
# \@units - reference to a list of unit,package & prebuilt nodes which implement this configuration
#
# Description
# This function processes the specified configuration to get the list of unit or package
# nodes that implement this configuration.
sub get_configuration_units2 ($$$$)	{
	my ($doc, $configuration, $verbose, $level) = @_;
	my @filterable_items; # list of individual buildable items
	my ($mrp, $bldFile);
	
	my ($model) = $doc->getElementsByTagName("systemModel");
	
	# Start with the units specified via listRefs, then append the
	# units specified via layerRefs - they will be sorted afterwards anyway
	my @listrefs = $configuration->getElementsByTagName("listRef");
	foreach my $child (@listrefs)		{
		my $issublevel = $child->getParentNode->getTagName ne "configuration";
		next if (($level==1 && $issublevel) || ($level==2 && !$issublevel));
		push @filterable_items, &find_unitList_by_ID($doc, $child->getAttribute("list"), 2);
	}
	my @refs = $configuration->getElementsByTagName("ref");
	foreach my $child (@refs)		{
		my $issublevel = $child->getParentNode->getTagName ne "configuration";
		next if (($level==1 && $issublevel) || ($level==2 && !$issublevel));		
		my $item = $child->getAttribute("item");
		# Find the named object and enumerate the items it contains
		my ($layer) = XML::XQL::solve("//*[\@name = '$item']", $model);
		if (!defined($layer))			{
			print $GenXml::gLogFileH "ERROR: no match for \"$item\"\n";
			next;
		}
		my @newunits = $layer->getElementsByTagName("unit",1);		
		my @components = $layer->getElementsByTagName("component",1);

		if ($verbose)			{
			printf $GenXml::gLogFileH "Layer \"$item\" contained %d untis in %d components, \n",
				 scalar @newunits,  scalar @components;
		}
		if (scalar @newunits == 0)	{
		  print $GenXml::gLogFileH "WARNING: ref $item contains no units\n";
		}
		if (scalar @components == 0)			{
			print $GenXml::gLogFileH "WARNING: ref $item contains no components\n";
		}
		push @filterable_items, @components, @newunits;
	}
  
	my @configspec = split /,/,$configuration->getAttribute("filter");
	my @unfiltered_items;
	
	# Scan the list, eliminating duplicates and elements which fail the filtering
	my %mrpfiles;
	foreach my $element (@filterable_items)	{
		my $name = $element->getAttribute("name");
		my $filter = $element->getAttribute("filter");
		my $class = $element->getAttribute("class");
				
		if ($filter)			{
			my $failed = &check_filter($filter,\@configspec);
			if ($failed ne "")				{
				print $GenXml::gLogFileH "Filtered out $name ($failed)\n" if ($verbose);
				next;
			}
		}
		if($element->getTagName eq 'unit')
			{
			# if it's not been filtered out, then substitute the unix syle path to windows style.
			$bldFile = $element->getAttribute("bldFile");
			if ($bldFile ne "")	{
				$bldFile =~ s/\//\\/g;
				$element->setAttribute("bldFile", $bldFile) ;
			}
			$mrp = $element->getAttribute("mrp");
			if ($mrp ne "")	{
				$mrp =~ s/\//\\/g;
				$element->setAttribute("mrp", $mrp) ;
			}
		
			if ($mrp)		{
				#my $elementName = $element->getAttribute("name");
				if (defined($mrpfiles{$mrp}))		{
					# eliminate duplicates
					next if ($mrpfiles{$mrp} eq $name);	
					# report (and eliminate) conflicts
					printf $GenXml::gLogFileH "WARNING: $mrp exists in %s and %s - skipping $name\n",
					  $name, $mrpfiles{$mrp};
					next;
				}
				$mrpfiles{$mrp} = $name;
			}
		}
		push @unfiltered_items, $element;
	}
	
	if ($verbose)	{
		printf $GenXml::gLogFileH "%s contains %d units and components at level %d\n", 
			$configuration->getAttribute("name"), scalar @unfiltered_items, $level;
	}
	
	# Process the tag "<specialInstructions" in the given configuration.  Need to convert the attribut "CWD" to windows style
	foreach my $child ($configuration->getElementsByTagName("specialInstructions"))	{
		my $command = $child->getAttribute("cwd");
		$command =~ s/\//\\/g;
		$child->setAttribute("cwd", $command);
	}
	return \@unfiltered_items;
}


1;
