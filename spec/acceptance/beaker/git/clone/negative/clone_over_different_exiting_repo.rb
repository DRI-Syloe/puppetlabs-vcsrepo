test_name 'C3482 - clone over an existing repo'

# Globals
repo_name = 'testrepo_already_exists'

hosts.each do |host|
  tmpdir = host.tmpdir('vcsrepo')
  step 'setup - create repo' do
    install_package(host, 'git')
    my_root = File.expand_path(File.join(File.dirname(__FILE__), '../../../../..'))
    scp_to(host, "#{my_root}/acceptance/files/create_git_repo.sh", tmpdir)
    on(host, "cd #{tmpdir} && ./create_git_repo.sh")
    on(host, "mkdir #{tmpdir}/#{repo_name}")
    on(host, "cd #{tmpdir}/#{repo_name} && git init")
    on(host, "cd #{tmpdir}/#{repo_name} && touch a && git add a && git commit -m 'a'")
  end

  teardown do
    on(host, "rm -fr #{tmpdir}")
  end

  step 'clone over existing repo using puppet' do
    on(host, "cd #{tmpdir}/#{repo_name} && git log --pretty=format:\"%h\"") do |res|
      @existing_sha = res.stdout
    end
    pp = <<-EOS
    vcsrepo { "#{tmpdir}/#{repo_name}":
      ensure => present,
      source => "file://#{tmpdir}/testrepo.git",
      provider => git,
    }
    EOS

    apply_manifest_on(host, pp)
  end

  step 'verify original repo was not replaced' do
    on(host, "cd #{tmpdir}/#{repo_name} && git log --pretty=format:\"%h\"") do |res|
      fail_test('original repo was replaced without force') unless res.stdout.include? "#{@existing_sha}"
    end
  end

end