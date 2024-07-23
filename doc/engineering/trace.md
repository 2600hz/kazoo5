- [Callflow trace feature](#orgda01c0d)
  - [Problem: Callers navigating a callflow can't be observed in real time without Pivot callbacks](#orge9b7a23)
  - [Solution: API + websocket events to enable tracing a callflow](#org51f2f28)
  - [General flow](#orgc8ffdeb)
  - [Blackhole / websockets](#org85ffc83)
  - [Query for trace events](#org5b77508)
  - [Cleanup up of trace events](#orgb34517c)
    - [Automatic cleanup](#orgc74450b)


<a id="orgda01c0d"></a>

# Callflow trace feature


<a id="orge9b7a23"></a>

## Problem: Callers navigating a callflow can't be observed in real time without Pivot callbacks

Only logging shows a particular call's execution path through a callflow.


<a id="org51f2f28"></a>

## Solution: API + websocket events to enable tracing a callflow

I envision an API like `PUT /v2/accounts/{ACCOUNT_ID}/callflows/{CALLFLOW_ID}/trace` to instruct KAZOO to put a trace on the callflow, have it follow the kapps\_call record so apps like conference, stepswitch, and pivot can implement tracing events as well.

-   PUT creates a "trace" doc with start/end time, callflow id (maybe other criteria later on like "trace to file" for download). Returns a trace ID, usable for subscribing to websocket events
-   kapi\_trace module for events to be published
-   bh module for subscribing and receiving trace events


<a id="orgc8ffdeb"></a>

## General flow

API client wants to trace callflow for their main number.

1.  Create a trace profile:
    
    ```bash
       curl -X PUT https://api.server:8443/v2/accounts/{ACCOUNT_ID}/traces \
       -d '{"data":{
              "name":"main cf trace"
              ,"start_time":{GREGORIAN_TIMESTAMP} // required
              ,"end_time":{GREGORIAN_TIMESTAMP}   // optional, defaults to X minutes after start_time
              ,"trace_type":"callflow"
              ,"trace_data": {
                "callflow_id":"{CALLFLOW_ID}"
              }
            }
           }'
    ```

"start\_time" and "end\_time" constrain the window KAZOO will activately execute the trace "trace\_type" will map to a kz\_trace<sub>TYPE</sub> module (so kz\_trace\_callflow in this case) "trace\_data" is an object fed to the module with specific data about how the trace module should work

The response to the API request will include a trace ID. Subsequent `GET /v2/accounts/{ACCOUNT_ID}/traces/{TRACE_ID}` requests will list trace events saved so far.

The `TRACE_ID` should follow CDR IDs and prepend the `YYYYMM-` of the start\_time to help the API more easily locate the MODB(s) involved in storing trace events

1.  The API client creates a websocket connection to blackhole and subscribes for `trace.{TRACE_ID}` events

2.  A call comes into the account and executes the callflow {CALLFLOW\_ID}
    
    I think kapps\_call:from\_route\_win/2 should ask the `kazoo_traces` core app for any traces to run (or maybe for now cf\_route\_win asks for
    
    The `kazoo_traces` app should maintain a gen\_listener that listens for doc\_\* events for docs with type `trace` (or whatever the pvt\_type ends up being) and stores them in an ETS table (just like webhooks does for webhook configs).
    
    That ETS table should be queried for the account's active traces:
    
    ```
       account_id =:= {ACCOUNT_ID}
       start_time =< kz_time:now_s()
       end_time =:= undefined OR end_time >= kz_time:now_s()
    ```
    
    Or if cf\_route\_win queries, include trace\_type=callflow + trace\_data.callflow\_id = {CALLFLOW\_ID}
    
    `kazoo_traces` should spawn a process to exec `kz_trace_callflow:trace(Call, TraceData, CallflowExePid)` (or some variant of this).
    
    This process should create a {TRACE\_INSTANCE\_UUID} for all events to be correlated with each other

Here we'll want to hook into cf\_exe and be notified when a new action proc is spawned (in cf\_exe:do\_launch\_cf\_module) and when typical call events are received (CHANNEL\_CREATE/ANSWER/BRIDGE/DESTROY, DTMF, RECORD\_START/STOP, CHANNEL\_TRANSFEROR/TRANSFEREE/REPLACED/PIVOT.

These events should generate a `trace_event` doc stored to the MODB for {TRACE\_ID} and a kapi\_trace:publish\_trace\_event/2.

Fields on this doc should include (but no necessarily limited to):

-   id = {UUID}
-   trace\_instance\_id = {TRACE\_INSTANCE\_ID}
-   trace\_id = {TRACE\_ID}
-   event\_timestamp = kz\_time:now\_ms()
-   event\_type = "channel\_event" | "callflow\_action"
-   event\_data = {&#x2026;} could be the raw call event or an object about the pid and cf module spawned
-   pvt\_type = "trace\_event"


<a id="org85ffc83"></a>

## Blackhole / websockets

Blackhole will need a bh\_trace.erl added to allow subscriptions by the API client and a bindings for AMQP to receive the trace events.


<a id="org5b77508"></a>

## Query for trace events

`GET /v2/accounts/{ACCOUNT_ID}/traces/{TRACE_ID}/instances` will fetch a list of `trace_instance_id` IDs with their corresponding timestamp range

`GET /v2/accounts/{ACCOUNT_ID}/traces/{TRACE_ID}/instances/{TRACE_INSTANCE_ID}` will fetch the list of trace events sorted by event\_timestamp


<a id="orgb34517c"></a>

## Cleanup up of trace events

Should the client want to cleanup a trace, support cleanup of trace instances and trace configs

`DELETE /v2/accounts/{ACCOUNT_ID}/traces/{TRACE_ID}/`

Delete the config and all trace instances

`DELETE /v2/accounts/{ACCOUNT_ID}/traces/{TRACE_ID}/instances/{TRACE_INSTANCE_ID}`

Delete just the "trace\_event" docs for this trace instance


<a id="orgc74450b"></a>

### Automatic cleanup

Here I am undecided just yet about whether to introduce a "task" that cleans up expired trace docs and their instances.

On the one hand, MODB archival will remove them from the DB cluster so they'll leave the "working set" naturally.

On the other hand, is a trace from 3 months ago worth keeping around? Methinks no but&#x2026;is there a downside to leaving the trace docs and their instance docs?

At this moment I would say no to automatic cleanup
