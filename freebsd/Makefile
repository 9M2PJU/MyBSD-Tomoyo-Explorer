# FreeBSD Port Makefile for MyBSD Tomoyo Explorer
PORTNAME=	tomoyo-explorer
PORTVERSION=	1.00.a
CATEGORIES=	x11-fm
MASTER_SITES=	https://github.com/9M2PJU/MyBSD-Tomoyo-Explorer/releases/download/v1.00-ALPHA/
DISTNAME=	bsd-explorer-v1.00-ALPHA

MAINTAINER=	9m2pju@gmail.com
COMMENT=	Classic BSD/Unix Ruby GTK 1.2 Graphical File Manager
WWW=		https://github.com/9M2PJU/MyBSD-Tomoyo-Explorer

LICENSE=	BSD2CLAUSE
LICENSE_FILE=	${WRKSRC}/README

RUN_DEPENDS=	ruby:lang/ruby18 \
		${RUBY_SITEARCHLIBDIR}/gtk.so:x11-toolkits/ruby-gtk \
		${RUBY_SITEARCHLIBDIR}/gdk_pixbuf.so:graphics/ruby-gdk_pixbuf

NO_BUILD=	yes
WRKSRC=		${WRKDIR}/bsd-explorer-v1.00-ALPHA

do-install:
	${MKDIR} ${STAGEDIR}${DATADIR}
	(cd ${WRKSRC} && ${COPYTREE_SHARE} . ${STAGEDIR}${DATADIR})
	${MKDIR} ${STAGEDIR}${PREFIX}/bin
	@${ECHO_CMD} '#!/bin/sh' > ${WRKDIR}/tomoyo-explorer
	@${ECHO_CMD} 'export EXPLORER_BASE="${DATADIR}"' >> ${WRKDIR}/tomoyo-explorer
	@${ECHO_CMD} 'exec ruby "${DATADIR}/explorer_alone" "$${1:-$$PWD}"' >> ${WRKDIR}/tomoyo-explorer
	${INSTALL_SCRIPT} ${WRKDIR}/tomoyo-explorer ${STAGEDIR}${PREFIX}/bin/tomoyo-explorer
	${LN} -sf tomoyo-explorer ${STAGEDIR}${PREFIX}/bin/bsd-explorer

.include <bsd.port.mk>
