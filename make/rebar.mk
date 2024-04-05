REBAR=$(ROOT)/.rebar/rebar3

.PHONY: rebar
rebar: $(REBAR)

$(REBAR):
	curl https://s3.amazonaws.com/rebar3/rebar3 --create-dirs --location -o $(REBAR)
	chmod +x $(REBAR)
