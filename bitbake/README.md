
# Build secapi3 using openssl for armv7vet2hf-neon-rdk-linux-gnueabi.

   Follwoing is using realtek skyxione as an example, I am using 6.6_secapi_x1 branch.

1. Create a folder named secapi3 under meta-rdk-comcast-video/recipes-extended/, then place 
   secapi_git.bb inside this folder.In the .bb file, the SRC_URI does not work, but it can create
   a folder under the build directory, as seen below:

   ```build-skyxione/tmp/work/armv7vet2hf-neon-rdk-linux-gnueabi/secapi3/1.99+git-r0```

2. Download the branch `secapi_openssl` from `https://github.com/seanjin99/tasecureapi/` and create a
   folder named secapi3 under generic/. Copy all the contents from 
   tasecureapi/reference/src to generic/secapi3.

3. In the build-skyxione directory, run `bitbake secapi3` The results will be found under:
   ```build-skyxione/tmp/work/armv7vet2hf-neon-rdk-linux-gnueabi/secapi3/1.99+git-r0/images/```


4. Under `build-skyxione/tmp/work/armv7vet2hf-neon-rdk-linux-gnueabi/secapi3/1.99+git-r0/images/usr/lib`,
   you will find the following files:
   ```
   libsaclient.so
   libsaclient.so.3.4.0
   ```
   use `libsaclient.so.3.4.0` to replace `/usr/lib/libsaclient.so.x.x.x` on realtek device.

   then on realtek device, after you delete all contents under /opt/drm and reboot, 

   you will hit following errors:
   ```
   WPEFramework[5088]:  06/04/24 17:38:40 ERROR /usr/src/debug/secapi3/1.99+git-r0/git/util/src/pkcs12.c:206
   (load_pkcs12_secret_key): NULL file
   WPEFramework[5088]:  06/04/24 17:38:40 ERROR /usr/src/debug/secapi3/1.99+git-r0/git/taimpl/src/porting/otp.c:88
   (get_root_key): load_pkcs12_secret_key failed
   ```
   This is due to secapi decrypts with the hard coded root key, which is not what FKPS is encrypting with.

5. Specific note, to get a secapi buildable target for ARM platform, many files under reference/src have
   been changed and checked into `https://github.com/seanjin99/tasecureapi/`, only use these files under
   reference/src to build secapi3 for ARM platform.
