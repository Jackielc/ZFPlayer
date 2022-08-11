
#组件自定义repo 源
#执行时会先清理废弃的repo, 再增加自定义repo
#eg: $pod_specify_repos = ['git@code.shihuo.cn:shihuoios/shihuomodulize/shmodulizespecs.git', 'https://github.com/CocoaPods/Specs.git']
$pod_specify_repos = []
#用于请理废弃repos
$pod_abandoned_repos = []
