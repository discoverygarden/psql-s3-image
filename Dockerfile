FROM alpine:3.23.3

RUN apk add aws-cli postgresql16-client

# --------------------------------------
# Package manifest: prints every installed package to the build log as
#   DGI-PKG <arch> <type> <name> <version>
# so security checks can read versions from the image build's job log.
# Keep this as the last step of the final stage.
# --------------------------------------
RUN a=$(uname -m); \
  awk -v a="$a" '/^P:/{p=substr($0,3)} /^V:/{print "DGI-PKG", a, "apk", p, substr($0,3)}' /lib/apk/db/installed; \
  true
