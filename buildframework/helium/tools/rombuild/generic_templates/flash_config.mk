#####################################################################
# Flash config files templates
#####################################################################

flash_config${languagepack.id}${customer.id}${uda.id}${memorycard.id}${massmemory.id}${image.type}:TYPE=${image.type}
flash_config${languagepack.id}${customer.id}${uda.id}${memorycard.id}${massmemory.id}${image.type}:TEMPLATE=${flash.config.publish.dir}/${flash.config.name}
flash_config${languagepack.id}${customer.id}${uda.id}${memorycard.id}${massmemory.id}${image.type}:EVALUATED_FILE_NAME=$(TEMPLATE)
flash_config${languagepack.id}${customer.id}${uda.id}${memorycard.id}${massmemory.id}${image.type}:
	$(call IMAKER,EVAL_VARIABLES)
	