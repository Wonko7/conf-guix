;; This is an operating system configuration generated
;; by the graphical installer.

(use-modules (gnu)
             (gnu packages)
             (gnu packages shells)
             (gnu packages networking)
             (gnu packages xdisorg)
             (srfi srfi-1))

;; Import nonfree linux module.
(use-modules (nongnu packages linux)
             (nongnu system linux-initrd))

(use-service-modules desktop networking ssh xorg)

(operating-system
  (kernel linux)
  (kernel-arguments '("net.ifnames=0" "biosdevname=0"))
  (initrd microcode-initrd)
  (firmware (list linux-firmware))

  (locale "en_GB.utf8")
  (timezone "Europe/Paris")
  (keyboard-layout (keyboard-layout "us" "dvorak" #:options '("ctrl:nocaps")))
  (host-name "enterprise")
  (users (cons* (user-account
                  (name "wjc")
                  (comment "Wjc")
                  (group "users")
                  (home-directory "/home/wjc")
                  (shell (file-append zsh "/bin/zsh"))
                  (supplementary-groups
                    '("wheel" "netdev" "audio" "video")))
                %base-user-accounts))
  (packages
   (append
    (map specification->package '("nss-certs" "isc-dhcp" "iwd" "wireguard-tools" "iproute2" "iw"
                                  "rsync" "zsh"))
    ;;(list (specifications->manifest '("nss-certs" "dhcpcd" "iwd" "wireguard-tools" "iproute2" "iw")))
    ;;(list (specifications->package "nss-certs" "dhcpcd" "iwd" "wireguard-tools" "iproute2" "iw"))
    %base-packages))
  (services
   (append
    (list (service xfce-desktop-service-type)
          (service openssh-service-type)
          (service tor-service-type)
          (service slim-service-type (slim-configuration (display ":0")
                                                         (vt "vt7")
                                                         (xorg-configuration (xorg-configuration
                                                                              (keyboard-layout keyboard-layout))))))
    (remove (lambda (s)
              (eq? (service-kind s) gdm-service-type))
            %desktop-services)))
  (setuid-programs (cons*
                    #~(string-append #$wireshark "/bin/dumpcap")
                    #~(string-append #$xscreensaver "/bin/xscreensaver")
                    %setuid-programs))
  (mapped-devices
   (list (mapped-device
          (source
           (uuid "125bf330-ff27-45d1-9cce-1dd96cb14975"))
          (target "vault")
          (type luks-device-mapping))))
  (file-systems
   (cons* (file-system
           (mount-point "/")
           (device "/dev/mapper/vault")
           ;; (options "subvol=_live/@guix")
           (needed-for-boot? #t)
           (type "btrfs")
           (dependencies mapped-devices))
          (file-system
           (mount-point "/mnt/vault")
           (device "/dev/mapper/vault")
           (type "btrfs")
           (dependencies mapped-devices))
          (file-system
           (mount-point "/home")
           (device "/dev/mapper/vault")
           (options "subvol=_live/@home")
           (type "btrfs")
           (dependencies mapped-devices))
          (file-system
           (mount-point "/data")
           (device "/dev/mapper/vault")
           (options "subvol=_live/@data")
           (type "btrfs")
           (dependencies mapped-devices))
          (file-system
           (mount-point "/work")
           (device "/dev/mapper/vault")
           (options "subvol=_live/@work")
           (type "btrfs")
           (dependencies mapped-devices))
          (file-system
           (mount-point "/junkyard")
           (device "/dev/mapper/vault")
           (options "subvol=_live/@junkyard")
           (type "btrfs")
           (dependencies mapped-devices))
          ;; not picked up by swap-devices. as long as root isn't a subvol not useful anyway...
          ;; (file-system
          ;;   (mount-point "/swap")
          ;;   (device "/dev/mapper/vault")
          ;;   (options "subvol=_live/@swap")
          ;;   (type "btrfs")
          ;;   (dependencies mapped-devices))
          (file-system
           (mount-point "/boot/efi")
           (device (uuid "6C21-E416" 'fat32))
           (type "vfat"))
          %base-file-systems))
  (swap-devices
   '("/swap/swapfile"))
  (bootloader
   (bootloader-configuration
    (bootloader grub-efi-bootloader)
    (target "/boot/efi")
    (keyboard-layout keyboard-layout))))
