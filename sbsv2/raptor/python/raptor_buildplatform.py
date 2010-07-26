#
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
# Classes, methods and regex available for use in log filters
#

# This particular file is preliminary and under development.

class BuildPlatform(object):
	""" A build platform is a set of configurations which share
	the same metadata. In other words, a set of configurations
	for which the bld.inf and MMP files pre-process to exactly
	the same text."""

	def __init__(self, build):
		evaluator = build.GetEvaluator(None, buildConfig)
		self.selfform= evaluator.CheckedGet("TRADITIONAL_PLATFORM")
		epocroot = evaluator.CheckedGet("EPOCROOT")
		self.epocroot = generic_path.Path(epocroot)

		sbs_build_dir = evaluator.CheckedGet("SBS_BUILD_DIR")
		self.sbs_build_dir = generic_path.Path(sbs_build_dir)
		flm_export_dir = evaluator.CheckedGet("FLM_EXPORT_DIR")
		self.flm_export_dir = generic_path.Path(flm_export_dir)
		self.cacheid = flm_export_dir
		if raptor_utilities.getOSPlatform().startswith("win"):
			self.platmacros = evaluator.CheckedGet( "PLATMACROS.WINDOWS")
		else:
			self.platmacros = evaluator.CheckedGet( "PLATMACROS.LINUX")


		# is this a feature variant config or an ordinary variant
		fv = evaluator.Get("FEATUREVARIANTNAME")
		if fv:
			variantHdr = evaluator.CheckedGet("VARIANT_HRH")
			variantHRH = generic_path.Path(variantHdr)
			self.isfeaturevariant = True
		else:
			variantCfg = evaluator.CheckedGet("VARIANT_CFG")
			variantCfg = generic_path.Path(variantCfg)
			if not variantCfg in variantCfgs:
				# get VARIANT_HRH from the variant.cfg file
				varCfg = getVariantCfgDetail(self.epocroot, variantCfg)
				variantCfgs[variantCfg] = varCfg['VARIANT_HRH']
				# we expect to always build ABIv2
				if not 'ENABLE_ABIV2_MODE' in varCfg:
					build.Warn("missing flag ENABLE_ABIV2_MODE in %s file. ABIV1 builds are not supported.",
										   str(variantCfg))
			variantHRH = variantCfgs[variantCfg]
			self.isfeaturevariant = False

			self.variant_hrh = variantHRH
			build.Info("'%s' uses variant hrh file '%s'", buildConfig.name, variantHRH)
			self.systeminclude = evaluator.CheckedGet("SYSTEMINCLUDE")


			# find all the interface names we need
			ifaceTypes = evaluator.CheckedGet("INTERFACE_TYPES")
			interfaces = ifaceTypes.split()

			for iface in interfaces:
				detail[iface] = evaluator.CheckedGet("INTERFACE." + iface)

			# not test code unless positively specified
			self.testcode = evaluator.CheckedGet("TESTCODE", "")

			# make a key that identifies this platform uniquely
			# - used to tell us whether we have done the pre-processing
			# we need already using another platform with compatible values.

			key = str(self.variant_hrh) \
				+ str(self.epocroot) \
			+ self.systeminclude \
			+ self.platform

			# Keep a short version of the key for use in filenames.
			uniq = hashlib.md5()
			uniq.update(key)

			plat.key = key
			plat.key_md5 = "p_" + uniq.hexdigest()
			del uniq

	def __hash__(self):
		return hash(self.platform) + hash(self.epocroot) + hash(self.variant_hrh) + hash(self.systeminclude) + hash(self.testcode)

	def __cmp__(self,other):
		return cmp(self.hash(), other.hash())


	@classmethod 
	def fromConfigs(configsToBuild, build):
		""" Group the list of configurations into "build platforms"."""
		platforms = Set()
		
		for buildConfig in configsToBuild:
			# get everything we need to know about the configuration
			plat = BuildPlatform(build = build)

			# compare this configuration to the ones we have already seen

			# Is this an unseen export platform?
			# concatenate all the values we care about in a fixed order
			# and use that as a signature for the exports.
			items = ['EPOCROOT', 'VARIANT_HRH', 'SYSTEMINCLUDE', 'TESTCODE', 'export']
			export = ""
			for i in  items:
				if i in detail:
					export += i + str(detail[i])

			if export in exports:
				# add this configuration to an existing export platform
				index = exports[export]
				self.ExportPlatforms[index]['configs'].append(buildConfig)
			else:
				# create a new export platform with this configuration
				exports[export] = len(self.ExportPlatforms)
				exp = copy.copy(detail)
				exp['PLATFORM'] = 'EXPORT'
				exp['configs']  = [buildConfig]
				self.ExportPlatforms.append(exp)

			# Is this an unseen build platform?
			# concatenate all the values we care about in a fixed order
			# and use that as a signature for the platform.
			items = ['PLATFORM', 'EPOCROOT', 'VARIANT_HRH', 'SYSTEMINCLUDE', 'TESTCODE']
			if raptor_utilities.getOSPlatform().startswith("win"):
				items.append('PLATMACROS.WINDOWS')
			else:
				items.append('PLATMACROS.LINUX')

			items.extend(interfaces)
			platform = ""
			for i in  items:
				if i in detail:
					platform += i + str(detail[i])

			if platform in platforms:
				# add this configuration to an existing build platform
				index = platforms[platform]
				BuildPlatforms[index]['configs'].append(buildConfig)
			else:
				# create a new build platform with this configuration
				platforms[platform] = len(self.BuildPlatforms)
				plat.configs = [buildConfig]
				BuildPlatforms.append(detail)

