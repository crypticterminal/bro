##! Implements notice functionality across clusters.

@load ./main
@load base/frameworks/cluster

module Notice;

# Define the event used to transport notices on the cluster.
global cluster_notice: event(n: Notice::Info);

redef Cluster::manager2worker_events += /Notice::begin_suppression/;
redef Cluster::worker2manager_events += /Notice::cluster_notice/;

@if ( Cluster::local_node_type() != Cluster::MANAGER )
# The notice policy is completely handled by the manager and shouldn't be 
# done by workers or proxies to save time for packet processing.
redef policy = {};

event Notice::begin_suppression(n: Notice::Info)
	{
	suppressing[n$note, n$identifier] = n;
	}

event Notice::notice(n: Notice::Info)
	{
	# Send the locally generated notice on to the manager.
	event Notice::cluster_notice(n);
	}

event bro_init() &priority=-3
	{
	# Workers and proxies need to disable the notice streams because notice
	# events are forwarded directly instead of being logged remotely.
	Log::disable_stream(Notice::LOG);
	Log::disable_stream(Notice::POLICY_LOG);
	Log::disable_stream(Notice::ALARM_LOG);
	}
@endif

@if ( Cluster::local_node_type() == Cluster::MANAGER )
event Notice::cluster_notice(n: Notice::Info)
	{
	# Raise remotely received notices on the manager
	NOTICE(n);
	}
@endif
