text = `hg summary`
$version = "0.8.0-#{text.match("parent:\s+(.+):")[1]}"
