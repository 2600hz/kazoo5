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
	relx \
	syslog \
	trie \
	yamerl \
	zucchini

ifeq ($(CIRCLECI),true)
    DEPS += coveralls
    dep_coveralls = git https://github.com/markusn/coveralls-erl 1.4.0
    DEPS += proper
endif

dep_amqp_client = hex 3.12.13

dep_amqp_dist = git https://github.com/2600hz/erlang-amqp_dist.git 581d4b53e1fb3e8247ad856bef106015304d1906

dep_esaml = git https://github.com/2600hz/erlang-esaml.git 9fe06697234113eb1a64a009a6a1167ba72c9c04
# priv app usage, branch 2600Hz-otp-26

# dep_certifi = hex 0.3.0
# Used by hackney, let it pull in certifi

# dep_chatterbox = hex 0.7.0
# used by apns4erl

# PRs merged!
# Based off latest commit on '2600hz-otp26' branch
dep_couchbeam = git https://github.com/2600hz/erlang-couchbeam 2687ae6969390c4f733196552716db41f4d9ac93

# 2600Hz branch
dep_hackney = git https://github.com/2600hz/erlang-hackney 7ae3831c1a56896d05d862de2c44cc751ae7790f

# Based off 2600Hz-2.12.0 branch
dep_cowboy = git https://github.com/2600hz/erlang-cowboy 50c21ad

dep_eflame = git https://github.com/2600hz/erlang-eflame 4faa5a7064b31903f71a90d6ad79c66fa63d591d
# used by kz_tracers

dep_eiconv = git https://github.com/zotonic/eiconv 1.0.0
# used by gen_smtp

dep_epgsql = git https://github.com/epgsql/epgsql 7ba52768cf0ea7d084df24d4275a88eef4db13c2
# used to store tabulator events, branch 2600Hz-otp-26

dep_erlang_localtime = git https://github.com/2600hz/erlang-localtime a0e19d15cd9c89c502a85b189eb8a7611bfb7548
# used by kazoo_documents, teletype, notify, crossbar, callflow
# branch 2600hz

dep_erlazure = git https://github.com/2600hz/erlang-erlazure.git 42cfbef9e0b30704123c0aee7144db1bb538a9d7
# used by kazoo_attachments, merged in lazedo/erlazure add-start-link changes
# added on top of latest master commit aee99060e1d420640b320bddc1ca8a5e92a46ce6

dep_erlcloud = git https://github.com/2600hz/erlang-erlcloud 9fd232d08063a691ed4294ce3b8e4b99bf84fdda
# 2600Hz-otp-26 branch
# used by kazoo_attachments and a crossbar test (cb_storage_tests)

dep_ersip = git https://github.com/2600hz/erlang-ersip 5125e187807eff8dd507baa7fa6113e374d08ccb
# used by properly, webhooks
# branch 2600Hz-otp-26

## Code reloaders for dev VMs, uncomment if desired
# dep_fs_event = git https://github.com/jamhed/fs_event 783400da08c2b55c295dbec81df0d926960c0346
# dep_fs_sync = git https://github.com/jamhed/fs_sync 2cf85cf5861221128f020c453604d509fd37cd53

dep_gen_smtp = git https://github.com/2600hz/erlang-gen_smtp aa45101978aabb38af9156e18ba37b9dc2fa3d83
# used by teletype, notify, and fax
# branch 2600Hz-otp-26-fixed

dep_getopt = git https://github.com/2600hz/erlang-getopt v1.0.1
# used in some scripts/ and sup

dep_gproc = git https://github.com/2600hz/erlang-gproc 9f71a37fce4d58480a742b44458e4937c77f55c5
# used by kazoo_events, webseq, konami, acdc, ecallmgr, callflow
# based off master branch atm (no 2600Hz commits)

# dep_horse = git https://github.com/ninenines/horse 4dc81d47c3116b38af673481402f34ce03f8936b
# used by kazoo_stdlib in some test modules
# uncomment if you want to do simple perf testing of code

dep_inet_cidr = git https://github.com/2600hz/erlang-inet_cidr.git 1.0.2
# used by kz_network_utils

dep_jesse = git https://github.com/2600hz/erlang-jesse 86174cc16f18002ad640e62b2b3a8d9bcb33b05d
# used by kazoo_schemas primarily

dep_jiffy = git https://github.com/2600hz/erlang-jiffy c3b68f0dba2851bc7b2c79abe802ed9bab57c887
# add an option to return error on duplicate key when decoding
# includes changes from lazedo/utf8
# used by kz_json, nklib, jesse, lager, maybe couchbeam if compiled

dep_lager = git https://github.com/2600hz/erlang-lager 3.9.2
# used everywhere

dep_lager_syslog = git https://github.com/2600hz/erlang-lager_syslog 3.0.3

dep_meck = git https://github.com/2600hz/erlang-meck 0.8.13
# used in tests for kazoo_voicemail, crossbar, teletype, and other deps

dep_nklib = git https://github.com/2600hz/erlang-nklib ed8097b4e3bac43864cfe5d522c7907b150b7037
# used by kzsip_uri and cb_registrations
# branch 2600Hz-otp-26

# dep_parse_trans = git https://github.com/lazedo/parse_trans
# appears unused

dep_plists = git https://github.com/2600hz/erlang-plists 909aec1ffc2dfd651b880af8138346daff1cc407
# used by a handful of core apps
# 2600Hz-otp-26 branch

dep_proper = git https://github.com/2600hz/erlang-proper a5ae5669f01143b0828fc21667d4f5e344aa760b
# used by kazoo_proper, knm, kazoo_caches, kazoo_bindings, kz_util_tests, kazoo_token_buckets, kazoo_stdlib
# used by apps hotornot and callflow
# otp 26 fixes from upstream in after this hash

dep_recon = git https://github.com/2600hz/erlang-recon 2.5.5

dep_ra = git https://github.com/2600hz/erlang-ra.git v1.1.2

dep_ranch = git https://github.com/2600hz/erlang-ranch 1.8.0

dep_reloader = git https://github.com/2600hz/erlang-reloader de1e6c74204b61ccf3b3652f05c6a7dec9e8257d
# Development-related for reloading beam files
# see rel/dev.vm.args and fixture_shell in make/kz.mk
# commit adds makefile for compile/clean

dep_syslog = git https://github.com/2600hz/erlang-syslog bbad537a1cb5e4f37e672d2e2665659e850662d0

# dep_wsock = git https://github.com/madtrick/wsock 1.1.7
# appears unused

dep_yamerl = git https://github.com/2600hz/erlang-yamerl v0.7.0
# used by kazoo_ast to create OpenAPI 3

dep_zucchini = git https://github.com/2600hz/erlang-zucchini 0.1.0
# INI file parser
# used by kazoo_config_init

dep_trie = git https://github.com/2600hz/erlang-trie v1.7.5
# used by hotornot

dep_cowlib = git https://github.com/2600hz/erlang-cowlib 2.13.0

dep_gun = git https://github.com/2600hz/erlang-gun 2600hz-2.0.0-pre.3

dep_apns = git https://github.com/2600hz/erlang-apns4erl.git 2600hz-2.4.1

dep_folsom = git https://github.com/2600hz/erlang-folsom 1f3f610d1498d4ae2625178daaac5fc4f5306969
# 2600Hz-otp-26 branch
# used by hangups


dep_fcm = git https://github.com/2600hz/erlang-fcm.git 573e437e1d1769d8f044a32c1d9cfa90dd4160b6
# Firebase cloud messaging
# used by pusher

dep_hep = git https://github.com/2600hz/hep-erlang 5f18e91e45d49d3d7013fc93897d5c12441d86d8
# Homer encapsulation protocol
# merged lazedo/hep changes
# added specs for dialyzer happiness

# runtime code generation
dep_meta = git https://github.com/2600hz/erlang-meta 0.1.3

# used for WSDL->record and WSDL RPC calls
dep_soap = git https://github.com/2600hz/erlang-soap dbdca66

# XML lib
dep_erlsom = git https://github.com/2600hz/erlang-erlsom 2600Hz

# OTP release builder
dep_relx = git https://github.com/erlware/relx v4.9.0

# Used by kazoo_auth
# 2600Hz-otp-2 6branch
dep_qrcode = git https://github.com/2600hz/erlang-qrcode 7faa72913a4f8267c10d8f4a82685f73122f00d6

dep_qdate = git https://github.com/2600hz/erlang-qdate 2072b49220dc0cfad59f1163119e1e76e55240a1
dep_qdate_localtime = git https://github.com/2600hz/erlang-qdate_localtime cee705be45df8bcdcc7f77d371d4b34ef52d369b

dep_elvis = git https://github.com/2600hz/erlang-elvis 2600Hz
