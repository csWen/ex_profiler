Application.ensure_all_started(:mimic)
Mimic.copy(:fprof)

ExUnit.start()
