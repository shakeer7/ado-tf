# Production design only

No executable production resources or destroy pipeline exist here. A real design
uses separate subscriptions and clusters for nonproduction and production,
private APIs and endpoints with routable agents, availability zones, supported
node sizing, at least three system nodes, backup and restore drills, policy,
signed artifacts, centralized logging, chargeback and independently protected
state. Budget, identity and data-retention controls require organization review.
