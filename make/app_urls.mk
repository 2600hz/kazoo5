## If you use SSH keys instead
## FETCH_AS = git@github.com:
##
## If you want to use https, use:
## FETCH_AS = https://github.com/
##
## https only works for public repos!
##
## To override these it is expected you either `export` this variable
## or set it in your `~/.bashrc` file.

ifeq ($(CI),)
	FETCH_AS ?= git@github.com:
	GT_FETCH_AS ?= git@gitlab.com:oomaforbin/oomacorp/
else
	FETCH_AS ?= https://github.com/

	## this is going to be fine, i hope :))
	GT_FETCH_AS ?= git@gitlab.com:oomaforbin/oomacorp/
endif

BASE_BRANCH ?= origin/5.4
BRANCH = $(subst origin/,,$(BASE_BRANCH))


dep_blackhole = git $(FETCH_AS)2600hz/kazoo-blackhole.git $(BRANCH)
dep_braintree = git $(GT_FETCH_AS)2600hz/kazoo-braintree.git $(BRANCH)
dep_call_inspector = git $(FETCH_AS)2600hz/kazoo-call-inspector.git $(BRANCH)
dep_callflow = git $(FETCH_AS)2600hz/kazoo-callflow.git $(BRANCH)
dep_cdr = git $(FETCH_AS)2600hz/kazoo-cdr.git $(BRANCH)
dep_conference = git $(FETCH_AS)2600hz/kazoo-conference.git $(BRANCH)
dep_crossbar = git $(FETCH_AS)2600hz/kazoo-crossbar.git $(BRANCH)
dep_doodle = git $(FETCH_AS)2600hz/kazoo-doodle.git $(BRANCH)
dep_ecallmgr = git $(FETCH_AS)2600hz/kazoo-ecallmgr.git $(BRANCH)
dep_fax = git $(FETCH_AS)2600hz/kazoo-fax.git $(BRANCH)
dep_hangups = git $(FETCH_AS)2600hz/kazoo-hangups.git $(BRANCH)
dep_hotornot = git $(FETCH_AS)2600hz/kazoo-hotornot.git $(BRANCH)
dep_jonny5 = git $(FETCH_AS)2600hz/kazoo-jonny5.git $(BRANCH)
dep_media_mgr = git $(FETCH_AS)2600hz/kazoo-media-mgr.git $(BRANCH)
dep_milliwatt = git $(FETCH_AS)2600hz/kazoo-milliwatt.git $(BRANCH)
dep_omnipresence = git $(GT_FETCH_AS)2600hz/kazoo-omnipresence.git $(BRANCH)
dep_pivot = git $(FETCH_AS)2600hz/kazoo-pivot.git $(BRANCH)
dep_pusher = git $(FETCH_AS)2600hz/kazoo-pusher.git $(BRANCH)
dep_registrar = git $(FETCH_AS)2600hz/kazoo-registrar.git $(BRANCH)
dep_reorder = git $(FETCH_AS)2600hz/kazoo-reorder.git $(BRANCH)
dep_skel = git $(FETCH_AS)2600hz/kazoo-skel.git $(BRANCH)
dep_stats = git $(FETCH_AS)2600hz/kazoo-stats.git $(BRANCH)
dep_stepswitch = git $(FETCH_AS)2600hz/kazoo-stepswitch.git $(BRANCH)
dep_sysconf = git $(FETCH_AS)2600hz/kazoo-sysconf.git $(BRANCH)
dep_tasks = git $(FETCH_AS)2600hz/kazoo-tasks.git $(BRANCH)
dep_teletype = git $(FETCH_AS)2600hz/kazoo-teletype.git $(BRANCH)
dep_trunkstore = git $(FETCH_AS)2600hz/kazoo-trunkstore.git $(BRANCH)
dep_webhooks = git $(FETCH_AS)2600hz/kazoo-webhooks.git $(BRANCH)

dep_kazoo_ast = git $(FETCH_AS)2600hz/kazoo-ast.git $(BRANCH)
