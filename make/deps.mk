## 3rd party dependencies
DEPS ?= amqp_client \
	amqp_dist \
	couchbeam \
	cowlib \
	cowboy \
	eflame \
	eiconv \
	epgsql \
	erlang_localtime \
	erlazure \
	erlcloud \
	erlsom \
	erlydtl \
	ersip \
	esaml \
	gen_smtp \
	getopt \
	gproc \
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
	ra \
	ranch \
	recon \
	reloader \
	syslog \
	yamerl \
	zucchini \
	trie \
	gun \
	folsom \
	apns \
	fcm \
	hep
# BUILD_DEPS = parse_trans
IGNORE_DEPS = hamcrest

ifeq ($(CIRCLECI),true)
    DEPS += coveralls
    dep_coveralls = git https://github.com/markusn/coveralls-erl 1.4.0
    DEPS += proper
endif

dep_amqp_client = hex 3.8.14

dep_amqp_dist = git https://github.com/2600hz/erlang-amqp_dist.git bd97a806a10bd16d97bf0be0d4676cf9fec047e6

dep_esaml = git https://github.com/2600hz/erlang-esaml.git master

# dep_certifi = hex 0.3.0
# Used by hackney, let it pull in certifi

# dep_chatterbox = hex 0.7.0
# used by apns4erl

# PRs merged!
#Based off latest master commit + Ming's _show work, _find, and a couple more commits
dep_couchbeam = git https://github.com/2600hz/erlang-couchbeam b355ae69064d5425c9ee5582e1933f5945ee9c18

# 2.9.0 tagged commit
dep_cowboy = git https://github.com/2600hz/erlang-cowboy 04ca4c5d31a92d4d3de087bbd7d6021dc4a6d409

dep_eflame = git https://github.com/slfritchie/eflame 7b0bb1a7e8c8482a59421a3a50ae69d49af59d52
# used by kz_tracers

dep_eiconv = git https://github.com/zotonic/eiconv 1.0.0
# used by gen_smtp

dep_epgsql = git https://github.com/epgsql/epgsql 4.5.0
# used to store tabulator events

dep_erlang_localtime = git https://github.com/2600hz/erlang-localtime 2600hz
# used by kazoo_documents, teletype, notify, crossbar, callflow

dep_erlazure = git https://github.com/2600hz/erlang-erlazure.git 88e0417251983ab4d8a2a2606c732906eecd5007
# used by kazoo_attachments, merged in lazedo/erlazure add-start-link changes

dep_erlcloud = git https://github.com/2600hz/erlang-erlcloud 3.2.7
# used by kazoo_attachments and a crossbar test (cb_storage_tests)

# latest master commit
dep_ersip = git https://github.com/2600hz/erlang-ersip 3548962b87a51c733680cd2e3cefd6a0ec1d3f42
# used by properly, webhooks

## Code reloaders for dev VMs, uncomment if desired
# dep_fs_event = git https://github.com/jamhed/fs_event 783400da08c2b55c295dbec81df0d926960c0346
# dep_fs_sync = git https://github.com/jamhed/fs_sync 2cf85cf5861221128f020c453604d509fd37cd53

# 1.1.1 tagged commit
dep_gen_smtp = git https://github.com/2600hz/erlang-gen_smtp 410557a4b52cbabc99062e2196fa0ec16c3c03a7
# used by teletype, notify, and fax

# 1.0.2 tagged commit
dep_getopt = git https://github.com/2600hz/erlang-getopt 1c963cecd75cb5f7b37f28737abb120e61390c62
# used in some scripts/ and sup

# latest master commit
dep_gproc = git https://github.com/2600hz/erlang-gproc 3737f2b958a5908d7a3870046ae162c5b9bf971c
# used by kazoo_events, webseq, konami, acdc, ecallmgr, callflow

# dep_horse = git https://github.com/ninenines/horse 4dc81d47c3116b38af673481402f34ce03f8936b
# used by kazoo_stdlib in some test modules
# uncomment if you want to do simple perf testing of code

# latest master commit
dep_inet_cidr = git https://github.com/2600hz/erlang-inet_cidr.git d776fb22dd43441e9011bd52f9b4b78116c26ab9
# used by kz_network_utils

# 1.6.1 tagged commit
dep_jesse = git https://github.com/2600hz/erlang-jesse ef0e038a0efa27c7e42fc6cfd963d06eec7c33d8
# used by kazoo_schemas primarily

dep_jiffy = git https://github.com/2600hz/erlang-jiffy 313d591cbda0fad5109fa8c049093984e54893a1
# add an option to return error on duplicate key when decoding
# includes changes from lazedo/utf8
# used by kz_json, nklib, jesse, lager, maybe couchbeam if compiled

# 3.9.2 tagged commit
dep_lager = git https://github.com/2600hz/erlang-lager 459a3b2cdd9eadd29e5a7ce5c43932f5ccd6eb88
# used everywhere

dep_lager_syslog = git https://github.com/2600hz/erlang-lager_syslog 3.0.3

# 0.9.2 tagged commit
dep_meck = git https://github.com/2600hz/erlang-meck 5aaa24886db404f995c9a91b421367f6bfe6e566
# used in tests for kazoo_voicemail, crossbar, teletype, and other deps

dep_nklib = git https://github.com/2600hz/erlang-nklib v0.4.1
# used by kzsip_uri and cb_registrations

# dep_parse_trans = git https://github.com/lazedo/parse_trans
# appears unused

dep_plists = git https://github.com/2600hz/erlang-plists 1.0.0
# used by a handful of core apps

# v1.4 tagged commit
dep_proper = git https://github.com/2600hz/erlang-proper 1daf130b0dfaea1f867751e43d82d7be7ebaa457
# used by kazoo_proper, knm, kazoo_caches, kazoo_bindings, kz_util_tests, kazoo_token_buckets, kazoo_stdlib
# used by apps hotornot and callflow

# 2.5.2 (latest tag)
dep_recon = git https://github.com/2600hz/erlang-recon 34194da6d9f8ed25f274e0ebb098dc9e95bcf547

dep_ra = git https://github.com/2600hz/erlang-ra.git v1.1.2

# 1.8.0 tagged commit
dep_ranch = git https://github.com/2600hz/erlang-ranch a692f44567034dacf5efcaa24a24183788594eb7

dep_reloader = git https://github.com/2600hz/erlang-reloader de1e6c74204b61ccf3b3652f05c6a7dec9e8257d
# Development-related for reloading beam files
# see rel/dev.vm.args and fixture_shell in make/kz.mk
# commit adds makefile for compile/clean

dep_syslog = git https://github.com/2600hz/erlang-syslog bbad537a1cb5e4f37e672d2e2665659e850662d0

# dep_wsock = git https://github.com/madtrick/wsock 1.1.7
# appears unused

# v0.8.1 tagged commit
dep_yamerl = git https://github.com/2600hz/erlang-yamerl 5a4bff28e4651b1fdb333e4c5c16fa44fb0e1b1f
# ref'd in kazoo_stdlib / kz_yaml.erl and used by kazoo_ast to create OpenAPI 3

dep_zucchini = git https://github.com/2600hz/erlang-zucchini 0.1.0
# INI file parser
# used by kazoo_config_init

# 2.0.2 tagged commit
dep_trie = git https://github.com/2600hz/erlang-trie f5b0628ddaf9ee2e4510a4986570794e3ca313f0
# used by hotornot

# 2.11.0 tagged commit
dep_cowlib = git https://github.com/2600hz/erlang-cowlib e9448e5628c8c1d9083223ff973af8de31a566d1

dep_apns = git https://github.com/2600hz/erlang-apns4erl.git 2600hz-2.4.1

dep_folsom = git https://github.com/2600hz/erlang-folsom 0.8.2
# used by hangups


dep_fcm = git https://github.com/2600hz/erlang-fcm.git b2f68a4c6f0f59475597a35e2dc9be13d9ba2910
# Firebase cloud messaging
# used by pusher

dep_hep = git https://github.com/2600hz/hep-erlang 5f18e91e45d49d3d7013fc93897d5c12441d86d8
# Homer encapsulation protocol
# merged lazedo/hep changes
# added specs for dialyzer happiness

# runtime code generation
dep_meta = git https://github.com/2600hz/erlang-meta 0.1.3
