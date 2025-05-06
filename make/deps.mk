## 3rd party dependencies
DEPS ?=  amqp_client \
	amqp_dist \
	apns \
	couchbeam \
	cowboy \
	cowlib \
	eflame \
	eiconv \
	elvis \
	epgsql \
	erlazure \
	erlcloud \
	erlsom \
	erlydtl \
	ersip \
	esaml \
	fcm \
	folsom \
	geas \
	gen_smtp \
	getopt \
	gproc \
	gun \
	hackney \
	hep \
	inet_cidr \
	jesse \
	jiffy \
	lager \
	lager_syslog \
	meck \
	meta \
	nklib \
	plists \
	poolboy \
	proper \
	qdate \
	qdate_localtime \
	qrcode \
	ra \
	ranch \
	recon \
	reloader \
	relx \
	soap \
	syslog \
	trie \
	yamerl \
	zucchini

ifeq ($(CIRCLECI),true)
    # only used by scripts/cover.escript
    DEPS += coveralls
    dep_coveralls = git https://github.com/markusn/coveralls-erl 1.4.0
endif

dep_amqp_client = hex 4.0.3

# branch: otp-26
dep_amqp_dist = git https://github.com/2600hz/erlang-amqp_dist.git 6429a2105d8bb5aa1420faee647e8b576005eda1

# priv app usage
# branch: 2600Hz-otp-26
dep_esaml = git https://github.com/2600hz/erlang-esaml.git 9fe06697234113eb1a64a009a6a1167ba72c9c04

# Used by hackney, let it pull in certifi
# dep_certifi = hex 0.3.0

# used by apns4erl
# dep_chatterbox = hex 0.7.0

# branch: 2600hz-otp26
dep_couchbeam = git https://github.com/2600hz/erlang-couchbeam b48830cd95aa61f86c7f6479f4425e80985802da

# branch: fix-intermittent-chunked-response-hang (until PR merged)
dep_hackney = git https://github.com/2600hz/erlang-hackney 1a13c8f8148e1e94ac633e905fc62bca78a483bf

# branch: 2600Hz-2.12.0
dep_cowboy = git https://github.com/2600hz/erlang-cowboy 50c21ad

# used by kz_tracers
# branch: 2600Hz-otp-26
dep_eflame = git https://github.com/2600hz/erlang-eflame 4faa5a7064b31903f71a90d6ad79c66fa63d591d

# used by gen_smtp
dep_eiconv = git https://github.com/zotonic/eiconv 1.0.0

# used to store tabulator events
# branch: devel
# tag: 4.7.1
dep_epgsql = git https://github.com/epgsql/epgsql 7ba52768cf0ea7d084df24d4275a88eef4db13c2

# used by kazoo_attachments
# branch: 2600hz-otp-26
dep_erlazure = git https://github.com/2600hz/erlang-erlazure.git 0b5a53e2d5e18f3dbe05a891596b607e7ca3989b

# used by kazoo_attachments and a crossbar test (cb_storage_tests)
# branch: 2600Hz-otp-26
dep_erlcloud = git https://github.com/2600hz/erlang-erlcloud 9fd232d08063a691ed4294ce3b8e4b99bf84fdda

# used by properly, webhooks
# branch: 2600Hz-otp-26
dep_ersip = git https://github.com/2600hz/erlang-ersip 5125e187807eff8dd507baa7fa6113e374d08ccb

## Code reloaders for dev VMs, uncomment if desired
# dep_fs_event = git https://github.com/jamhed/fs_event 783400da08c2b55c295dbec81df0d926960c0346
# dep_fs_sync = git https://github.com/jamhed/fs_sync 2cf85cf5861221128f020c453604d509fd37cd53

# used by teletype, notify, and fax
# branch: 2600Hz-otp-26-fixed
dep_gen_smtp = git https://github.com/2600hz/erlang-gen_smtp 04c8bcbaafff47f8c15f30d6255c726402e836c6

# used in some scripts/ and sup
dep_getopt = git https://github.com/2600hz/erlang-getopt v1.0.1

# used by kazoo_events, webseq, konami, acdc, ecallmgr, callflow
# branch: master
dep_gproc = git https://github.com/2600hz/erlang-gproc 9f71a37fce4d58480a742b44458e4937c77f55c5

# used by kazoo_stdlib in some test modules
# uncomment if you want to do simple perf testing of code
# branch: master
# dep_horse = git https://github.com/ninenines/horse 4dc81d47c3116b38af673481402f34ce03f8936b

# used by kz_network_utils
dep_inet_cidr = git https://github.com/2600hz/erlang-inet_cidr.git 1.0.2

# used by kazoo_schemas primarily
# branch: otp-26 + external format validator
dep_jesse = git https://github.com/2600hz/erlang-jesse 35eabb483c3541ca0ad631b7bc5e333655303205

# used by kz_json, nklib, jesse, lager, maybe couchbeam if compiled
# branch: 2600hz
dep_jiffy = git https://github.com/2600hz/erlang-jiffy c3b68f0dba2851bc7b2c79abe802ed9bab57c887

# used everywhere
dep_lager = git https://github.com/2600hz/erlang-lager 6159a9497be54ac94fe00d9b9940b1bb7e423021

dep_lager_syslog = git https://github.com/2600hz/erlang-lager_syslog 3.0.3

# used in tests for kazoo_voicemail, crossbar, teletype, and other deps
dep_meck = git https://github.com/2600hz/erlang-meck 0.8.13

# used by kzsip_uri and cb_registrations
# branch: 2600Hz-otp-26
dep_nklib = git https://github.com/2600hz/erlang-nklib ed8097b4e3bac43864cfe5d522c7907b150b7037

# dep_parse_trans = git https://github.com/lazedo/parse_trans
# appears unused

# used by a handful of core apps
# branch: 2600Hz-otp-26
dep_plists = git https://github.com/2600hz/erlang-plists 909aec1ffc2dfd651b880af8138346daff1cc407

dep_poolboy = git https://github.com/2600hz/erlang-poolboy 9212a8770edb149ee7ca0bca353855e215f7cba5

# used by kazoo_proper, knm, kazoo_caches, kazoo_bindings, kz_util_tests, kazoo_token_buckets, kazoo_stdlib
# used by apps hotornot and callflow
# branch: master
dep_proper = git https://github.com/2600hz/erlang-proper a5ae5669f01143b0828fc21667d4f5e344aa760b

dep_recon = git https://github.com/2600hz/erlang-recon 2.5.5

dep_ra = git https://github.com/2600hz/erlang-ra.git v2.15.0

dep_ranch = git https://github.com/2600hz/erlang-ranch 1.8.0

# Development-related for reloading beam files
# see rel/dev.vm.args and fixture_shell in make/kz.mk
# commit adds makefile for compile/clean
# branch: master
dep_reloader = git https://github.com/2600hz/erlang-reloader de1e6c74204b61ccf3b3652f05c6a7dec9e8257d

dep_syslog = git https://github.com/2600hz/erlang-syslog bbad537a1cb5e4f37e672d2e2665659e850662d0

# dep_wsock = git https://github.com/madtrick/wsock 1.1.7
# appears unused

# used by kazoo_ast to create OpenAPI 3
dep_yamerl = git https://github.com/2600hz/erlang-yamerl v0.7.0

# INI file parser
# used by kazoo_config_init
dep_zucchini = git https://github.com/2600hz/erlang-zucchini 0.1.0

# used by hotornot
dep_trie = git https://github.com/2600hz/erlang-trie v1.7.5

dep_cowlib = git https://github.com/2600hz/erlang-cowlib 2.13.0

dep_gun = git https://github.com/2600hz/erlang-gun 2.1.0

dep_apns = git https://github.com/2600hz/erlang-apns4erl.git 2600hz-2.4.1

# used by hangups
# branch: 2600Hz-otp-26
dep_folsom = git https://github.com/2600hz/erlang-folsom 1f3f610d1498d4ae2625178daaac5fc4f5306969

# Firebase cloud messaging
# used by pusher
# branch: 2600Hz
dep_fcm = git https://github.com/2600hz/erlang-fcm.git 3e979c765c24b19dc475d954bb20f7ffb2e019b3

# Homer encapsulation protocol
# branch: master
dep_hep = git https://github.com/2600hz/hep-erlang 5f18e91e45d49d3d7013fc93897d5c12441d86d8

# runtime code generation
dep_meta = git https://github.com/2600hz/erlang-meta 0.1.3

# Detect OTP versions available given the codebase
dep_geas = git https://github.com/crownedgrouse/geas 2.9.1

# used for WSDL->record and WSDL RPC calls
dep_soap = git https://github.com/2600hz/erlang-soap dbdca66

# XML lib
# branch: 2600Hz
dep_erlsom = git https://github.com/2600hz/erlang-erlsom fb5f88a7635341520e3251b5354479ceee5fa8b1

# OTP release builder
dep_relx = git https://github.com/erlware/relx a9c35b6a159662cfae9ed8beaa62b7756b48765c

# Used by kazoo_auth
# branch: 2600Hz-otp-26
dep_qrcode = git https://github.com/2600hz/erlang-qrcode 1ce2d131f670a9ea89123694419e144047c8d362

# branch: master
dep_qdate = git https://github.com/2600hz/erlang-qdate 108c79668779bcbfb37f130ce31cb08f2483bd1d


# branch: master
dep_qdate_localtime = git https://github.com/2600hz/erlang-qdate_localtime cee705be45df8bcdcc7f77d371d4b34ef52d369b

# branch: 2600Hz-OTP27
dep_elvis = git https://github.com/2600hz/erlang-elvis 8ebeb66775f82bcf813d39a98f2564850e810cfc
