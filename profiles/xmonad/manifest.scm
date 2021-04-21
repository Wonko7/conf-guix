(use-modules (gnu)
             (gnu packages commencement)
             (guix profiles))
(use-package-modules haskell haskell-xyz wm gcc)

(packages->manifest (list gcc-toolchain ghc ghc-hostname ghc-xmonad-contrib xmonad))
