(cons* (channel
	(name 'nonguix)
	(url "https://gitlab.com/nonguix/nonguix")
	(introduction
	 (make-channel-introduction
	  "897c1a470da759236cc11798f4e0a5f7d4d59fbc"
	   (openpgp-fingerprint
	    "2A39 3FFF 68F4 EF7A 3D29 12AF 6F51 20A0 22FB B2D5"))))
       (channel
         (name 'w7)
         (url "https://gitlab.com/wonko7/w7-guix-channel")
         (introduction
           (make-channel-introduction
             "e6afee0a2c3e941e186b2a9035c0217e5e94e9d5"
             (openpgp-fingerprint
               "FF23 0627 4DFE CF36 3AD8  677C 613C 8B66 6DBE 0AEB"))))
       %default-channels)
