# jsPsychAdmin 0.3.5.903

Minor updates

* Fix issue in check_status_participants_protocol() when no assigned participants


# jsPsychAdmin 0.3.5.902

Minor updates

* Sync version number with admin, maker, monkeys and manual
* All non-mysql credentials parameters are now credentials_file instead of list_credentials
* Add function to check if daily backups are done, to avoid multiple runs
* clean_up_dev_protocol(): ask to delete the pid + 999 MySQL tables also, as we commonly use this for dev protocols

# jsPsychAdmin 0.2

- admin/sync_data_active_protocols.R running
- more common_tasks
- Improvements to clean_up_dev_protocol and download_check_all_protocols

# jsPsychAdmin 0.1

- Initial version, trying to centralize the admin scripts
