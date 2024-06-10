ARCH=armv7hl
KERNEL_PACKAGE_DIR=kernel-adaptation-msm8916
KERNEL_PACKAGE=kernel-adaptation-msm8909

need_repo packages/qrtr \
    https://github.com/sailfish-on-sparkler/qrtr-rpm.git
need_repo packages/rmtfs \
    https://github.com/sailfish-on-sparkler/rmtfs-rpm.git
need_repo packages/mipi-dbi-configs \
    https://github.com/sailfish-on-sparkler/mipi-dbi-configs.git
need_repo packages/msm-firmware-loader \
    https://github.com/sailfish-on-sparkler/msm-firmware-loader-rpm.git
need_repo packages/msm-port-opener \
    https://github.com/sailfish-on-sparkler/msm-port-opener.git
need_repo packages/kernel-adaptation-msm8916 \
    https://github.com/sailfish-on-sparkler/kernel-adaptation-msm8916.git
need_repo packages/device-configuration-sparkler \
    https://github.com/sailfish-on-sparkler/device-configuration-sparkler.git
need_repo packages/device-sparkler-img-boot \
    https://github.com/sailfish-on-sparkler/device-sparkler-img-boot.git

DEFAULT_MW="qrtr rmtfs mipi-dbi-configs msm-firmware-loader msm-port-opener"
