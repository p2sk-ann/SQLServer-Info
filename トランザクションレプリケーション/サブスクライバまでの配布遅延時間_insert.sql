--■ DistributionAgenet
--★distributer-subscriberの遅延を確認
INSERT INTO ReplicationCheck_Distributor_1
SELECT
	 @@SERVERNAME
	,agent_id
	,name
	,max(delivery_latency / (1000 * 60)) as max_latency_min
	,getdate() as registDT
FROM distribution.dbo.msdistribution_history WITH (NOLOCK)
JOIN distribution.dbo.MSdistribution_agents with(nolock) on id = agent_id
WHERE datediff(MINUTE, TIME, getdate()) < 10 --直近10分以内に限定
GROUP BY agent_id, name
