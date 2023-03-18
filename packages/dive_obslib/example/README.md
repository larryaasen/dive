# example

## Special instructions

The bulid phase includes one extra Run Script. Here is a copy of that script:

```
# Copy the framework resources to a specific folder in the app Resources
cp -R ${TARGET_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}/obslib.framework/Resources/data ${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}
rsync ${TARGET_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}/obslib.framework/PlugIns/* ${TARGET_BUILD_DIR}/${PLUGINS_FOLDER_PATH}
cp ${TARGET_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}/obslib.framework/Resources/obs-ffmpeg-mux ${TARGET_BUILD_DIR}/${EXECUTABLE_FOLDER_PATH}
codesign --force --sign - ${TARGET_BUILD_DIR}/${EXECUTABLE_FOLDER_PATH}/obs-ffmpeg-mux
```
