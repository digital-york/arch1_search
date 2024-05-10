# Archibishops Registers Search Application

This code has been written by many contributors. It is currently maitained by DTI Team at the UoY Libraries. 

- Repo-Status: Active
- Repo-Contents: System
- Repo-Service-Name: Archibiships Registers Search Application
- Repo-Ownership-Rating: 3
- Repo-Quality-Rating: 2
- Repo-Next-Review-Due: 2024-10-01
- Repo-Expected-Retirement-Date: 2025-12-30
  
# About ARCH1_SEARCH

Arch1_Search is a Hydra-based, Ruby on Rails search and browse application built for the 'York's Archbishops' Registers Revealed' project. The project was funded by the Andrew W. Mellon Foundation.

The application powered by this code is available: http://archbishopsregisters.york.ac.uk

This code is made freely available, without warranty. It relies on the existence of a Fedora4 repository and solr instance containing data structured according the models here and in the accompanying arch1 application codebase: https://github.com/digital-york/arch1

For further information on the underlying data model, please see this (google document)[https://docs.google.com/document/d/1U3sLgaJr07d7LfvyDPT2rUnVAI1ccWp-Zeon_rlBd6o/edit]

Please contact us if you would like to make use of the codebase: dlib-info@york.ac.uk


= Local development quick start ==

Note: This version has been tested Ruby 2.7.x and Rails 5.2.x

0. Set up local environment in _.env_ file. Copy default values from _.env-sample_

1. Update all gems
    ``` bundle install ```

2. Start Solr and Fedora. *Note* Follow steps from [this Evernote](https://www.evernote.com/l/AWdxHSOyL7xEppQF_BkWW6Vmih8loRkzlYU) to restore Fedora backup (restricted access) data and reindex all content.
    ```
      bundle exec solr_wrapper
      bundle exec fcrepo_wrapper
    ```

3. Run rails server
    ``` bundle exec rails s ```

or Rails console
  ``` bundle exec rails c ```
