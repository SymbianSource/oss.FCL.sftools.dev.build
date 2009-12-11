
from raptor_tests import SmokeTest, ReplaceEnvs
import os

def generate_files():
	try:
		os.makedirs(ReplaceEnvs("$(SBS_HOME)/test/timing_tests/test_resources/parse_time"))
	except:
		pass
	bldinf_path = ReplaceEnvs("$(SBS_HOME)/test/timing_tests/test_resources/parse_time/bld.inf")
	bldinf = open(bldinf_path, "w")
	bldinf_content = """prj_mmpfiles
"""
	test_dir = ReplaceEnvs("$(SBS_HOME)/test/timing_tests/test_resources/parse_time")
	for number in range(0, 250):
		mmp_path = ("parse_timing_" + str(number).zfill(3) + ".mmp")
		mmp_file = open((test_dir + "/" + mmp_path), "w")
		mmp_file.write("""targettype	none
""")
		mmp_file.close()
		bldinf_content += (mmp_path + "\n")
		
	bldinf_content += "\nprj_exports\n"

	for number1 in range(0, 10):
		source_dir = ("export_source_" + str(number1))
		try:
			os.mkdir(test_dir + "/" + source_dir)
		except:
			pass
		
		for number2 in range (0, 10):
			source_file = ("/file_" + str(number2) + ".txt ")
			export_file = open((test_dir + "/" + source_dir + source_file), "w")
			export_file.write(str(number2))
			export_file.close()
			
			for number3 in range (0, 10):
				dest_dir = ("epoc32/include/export_destination_" + \
						str(number1) + str(number2) + str(number3))
				
				for number4 in range(0, 10):
					bldinf_content += source_dir + source_file + dest_dir + \
							"/export_destination_" + str(number4) + "\n"
	bldinf.write(bldinf_content)
	bldinf.close()
	
	
def delete_files():
	import shutil
	
	test_dir = ReplaceEnvs("$(SBS_HOME)/test/timing_tests/test_resources/parse_time")
	objects = os.listdir(test_dir)
	for object in objects:
		object_path = (test_dir + "/" + object)
		if os.path.isfile(object_path):
			os.remove(object_path)
		else:
			shutil.rmtree(object_path)
	

def run():
	
	generate_files()
	
	t = SmokeTest()
	
	t.id = "1"
	t.name = "parse_time_exports_mmps"
	t.description = """Test to measure time taken to parse a large number of
			exports and mmps"""
	t.command = "sbs -b timing_tests/test_resources/parse_time/bld.inf -n " + \
			"-c armv5_urel --toolcheck=off --timing"
	t.run()
	
	delete_files()
	return t
