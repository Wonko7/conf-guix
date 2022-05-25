(use-modules (gnu)
             (gnu packages)
             (gnu packages shells)
             (gnu packages networking)
             (gnu packages xdisorg)
             (gnu system setuid)
             (nongnu packages linux)
             (nongnu system linux-initrd)
             (guix gexp)
             (ice-9 format)
             (srfi srfi-1)
             (srfi srfi-88)
             ;; (w7)
             )

;; The following code is from
;; [[https://www.draketo.de/software/guile-capture-stdout-stderr.html]].

;; Comments and some formatting by me.

;; Related links:

;; https://www.gnu.org/software/guile/manual/html_node/Pipes.html
;; https://www.gnu.org/software/guile/manual/guile.html#Ports-and-File-Descriptors

;; This is an example of how you can write a procedure, which allows you to run
;; a shell command from GNU Guile and capture not only its stdout output in a
;; string, but also its stderr output in a string. This can be useful, if you
;; need to parse the output of both stdout and stderr.

;; Import nonfree linux module.
(use-modules (nongnu packages linux)
             (nongnu system linux-initrd))

(use-service-modules desktop networking ssh xorg docker)

(define hostname (getenv "HOST"))

(define host
  (cond ((or (string=? hostname "enterprise")
             (string=? hostname "yggdrasill"))
         (begin
           (display (string-append "building for " hostname "\n"))
           (string->keyword hostname)))
        (#t (error (string-append "unknown host: " hostname "\n") 69))))

(define machine-config
  (let ((initial  '((#:enterprise .
                     ((#:uuids .
                       ((#:vault . "125bf330-ff27-45d1-9cce-1dd96cb14975")
                        (#:efi . "6C21-E416")))))
                    (#:yggdrasill .
                     ((#:uuids .
                       ((#:vault . "077c1391-b290-4921-ae90-f8e3cec68113")
                        (#:efi . "77DE-0AE2"))))))))
    initial))

(define (nassq alist ks)
  (fold (lambda (k al) (assq-ref al k)) alist ks))

(operating-system
  (kernel linux)
  (kernel-arguments '("net.ifnames=0" "biosdevname=0"))
  (initrd microcode-initrd)
  (firmware (list linux-firmware))

  (locale "en_GB.utf8")
  (timezone "Europe/Paris")
  (keyboard-layout (keyboard-layout "us" "dvorak" #:options '("ctrl:nocaps")))
  (host-name (keyword->string host))
  (users (cons* (user-account
                  (name "wjc")
                  (comment "Wjc")
                  (group "users")
                  (home-directory "/home/wjc")
                  (shell (file-append zsh "/bin/zsh"))
                  (supplementary-groups
                   '("docker" "wheel" "netdev" "audio" "video")))
                (user-account
                  (name "tina")
                  (comment "Tina")
                  (group "users")
                  (home-directory "/home/tina")
                  (shell (file-append zsh "/bin/zsh"))
                  (supplementary-groups
                    '("netdev" "audio" "video")))
                %base-user-accounts))
  (packages
   (append
    (map specification->package '("nss-certs" "isc-dhcp" "wireguard-tools" "iproute2" "iw"
                                  "skim" "ripgrep" "git" "rsync" "zsh")) ;; TODO remove skim & rg once full emacs OS is operational.
    %base-packages))
  (services
   (cons* (service xfce-desktop-service-type)
          (service openssh-service-type)
          (service tor-service-type)
          (service docker-service-type)
          (service guix-publish-service-type
                   (guix-publish-configuration
                    (host "0.0.0.0")
                    (port 1691)
                    (advertise? #t)))
          (modify-services %desktop-services
                           (guix-service-type config => (guix-configuration
                                                         (inherit config)
                                                         (substitute-urls
                                                          (append (list "https://substitutes.nonguix.org")
                                                                  %default-substitute-urls))
                                                         (authorized-keys
                                                          (append (list (local-file "./data/substitutes/nonguix.pub"))
                                                                  %default-authorized-guix-keys))))
                           (gdm-service-type config =>
                                             (gdm-configuration (inherit config)
                                                                (xorg-configuration (xorg-configuration
                                                                                     (keyboard-layout keyboard-layout)))
                                                                (auto-login? #t)
                                                                (default-user "wjc"))))))

  (setuid-programs
   (cons*
    (setuid-program (program (file-append wireshark "/bin/dumpcap")))
    (setuid-program (program (file-append xscreensaver "/bin/xscreensaver")))
    %setuid-programs))

  (mapped-devices
   (list (mapped-device
          (source
           (uuid (nassq machine-config `(,host #:uuids #:vault))))
          (target "vault")
          (type luks-device-mapping))))
  (file-systems
   (cons* (file-system
           (device "/dev/mapper/vault")
           (mount-point "/")
           (type "btrfs")
           (options "subvol=_live/@guix-root")
           (needed-for-boot? #t)
           (dependencies mapped-devices))
          (file-system
           (mount-point "/mnt/vault")
           (device "/dev/mapper/vault")
           (type "btrfs")
           (dependencies mapped-devices))
          (file-system
           (mount-point "/home")
           (device "/dev/mapper/vault")
           (options "subvol=_live/@guix-home") ;; gentoo-home for ygg.
           (type "btrfs")
           (dependencies mapped-devices))
          (file-system
           (mount-point "/code")
           (device "/dev/mapper/vault")
           (options "subvol=_live/@code")
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
          ;; tested on yggdrasill only:
          (file-system
           (mount-point "/boot")
           (device (uuid (nassq machine-config `(,host #:uuids #:efi)) 'fat32))
           (type "vfat"))
          %base-file-systems))
  (swap-devices
   (list
    (swap-space
     (target "/mnt/vault/swap/swapfile")
     (dependencies mapped-devices))))
  (bootloader
   (bootloader-configuration
    (bootloader grub-efi-bootloader)
    (targets '("/boot"))
    (keyboard-layout keyboard-layout))))
