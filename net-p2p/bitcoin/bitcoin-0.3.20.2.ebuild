# Copyright 2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="2"

WX_GTK_VER="2.9"  # Should be fine like this.

inherit distutils eutils wxwidgets db-use versionator

DESCRIPTION="A peer-to-peer network based digital currency."
HOMEPAGE="http://bitcoin.org/"
SRC_URI="mirror://sourceforge/bitcoin/${P}-linux.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~x86 ~amd64"
IUSE="+daemon gui nls sse2"

DEPEND="gui? ( x11-libs/wxGTK:2.9[X] 
		>=app-admin/eselect-wxwidgets-0.7-r1
		)
	dev-libs/crypto++
	dev-libs/openssl[-bindist]
	dev-libs/boost
	sys-libs/db:4.8"
RDEPEND="${DEPEND}
	dev-util/pkgconfig"

# Version 0.3.20.02 provides a tarball with 0.3.20.2
S="${WORKDIR}/${PN}-${PV}"

pkg_setup() {
	# Used by daemon, not needed by gui.
	if use daemon; then
		ebegin "Creating bitcoin user and group"
		enewgroup bitcoin
		enewuser bitcoin -1 -1 /var/lib/bitcoin bitcoin
	fi;
}


src_prepare() {
     	# Create missing directories
	mkdir -p ${S}/src/obj/nogui || die "mkdir failed"

	# Copy our Makefile
	cp "${FILESDIR}/Makefile.gentoo" "${S}/src/Makefile" || die "Makefile copy failed"
	# Replace the berkdb cflags with the ones on our system.
	einfo "Berkeley DB: "
	sed -i -e "s:@@GENTOO_DB_INCLUDEDIR@@:$(db_includedir):g" \
		"${S}/src/Makefile"
	# Set the sse2 code
	if use sse2; then
		einfo "Enabling SSE2 code"
		sed -i -e "s:@@GENTOO_CXXFLAGS_SSE2@@:-DFOURWAYSSE2:g" \
			"${S}/src/Makefile"
		sed -i -e "s:@@GENTOO_SHA256_SSE2@@:-msse2 -O3 -march=amdfam10:g" \
			"${S}/src/Makefile"
	else
		# No sse2 code.
		sed -i -e "s:@@GENTOO_CXXFLAGS_SSE2@@::g" \
			"${S}/src/Makefile"
		sed -i -e "s:@@GENTOO_SHA256_SSE2@@::g" \
			"${S}/src/Makefile"
	fi
}

src_compile() {
	cd "${S}/src"
	if use gui; then
		emake bitcoin || die "emake bitcoin failed"
	fi
	if use daemon; then
		emake bitcoind || die "emake bitcoind failed"
	fi
	if ! use gui && ! use daemon; then
		einfo "No gui or daemon USE flag selected. Building daemon."
		emake bitcoind || die "emake bitcoind failed"
	fi
}

src_install() {
	cd "${S}/src"
	if use gui; then
		# Install when we build the gui version
		dobin bitcoin
		insinto /usr/share/pixmaps
		cd "${S}/src/rc"
		doins bitcoin.ico
		make_desktop_entry ${PN} "Bitcoin" "/usr/share/pixmaps/bitcoin.ico" "Network;P2P"
	fi
	cd "${S}/src"
	if use daemon || ( ! use gui && ! use daemon ); then
		# Install when we build the daemon version
		dobin bitcoind
		insinto /etc/bitcoin
		# RPC configuration (user and password).
		newins "${FILESDIR}/bitcoin.conf" bitcoin.conf
		# For daemons eyes only.
		fowners bitcoin:bitcoin /etc/bitcoin/bitcoin.conf
		fperms 600 /etc/bitcoin/bitcoin.conf
		# Init script and configuration
		newconfd "${FILESDIR}/bitcoin.confd" bitcoin
		newinitd "${FILESDIR}/bitcoin.initd" bitcoin
		# Bitcoinds home dir, restrict to that user only.
		# Contains wallet.dat and we don't want other users stealing it.
		diropts -m700
		dodir /var/lib/bitcoin
		fowners bitcoin:bitcoin /var/lib/bitcoin 
		# To stop bitcoind we need the symlink (su doesn't let bitcoind know about /etc/bitcoin/bitcoin.conf).
		dodir /var/lib/bitcoin/.bitcoin
		fowners bitcoin:bitcoin /var/lib/bitcoin/.bitcoin
		dosym /etc/bitcoin/bitcoin.conf /var/lib/bitcoin/.bitcoin/bitcoin.conf
	fi
	cd "${S}/locale/"
	if use nls; then
		# Check what LINGUAS are set and install the language files if they exsist.
		einfo "Installing language files"
		for val in ${LINGUAS}
		do
			if [ -e "$val/LC_MESSAGES/bitcoin.mo" ]; then
				einfo "$val"
				insinto "/usr/share/locale/$val/LC_MESSAGES/"
				doins "$val/LC_MESSAGES/bitcoin.mo"
			fi
		done
	fi
	cd "${S}"
	# Documentation: change to unix line end and install.
	edos2unix *.txt
	dodoc *.txt
}