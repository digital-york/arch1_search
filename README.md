== ARCH1_SEARCH

Arch1_Search is a Hydra-based, Ruby on Rails search and browse application built for the 'York's Archbishops' Registers Revealed' project. The project was funded by the Andrew W. Mellon Foundation.

The application powered by this code is available: http://archbishopsregisters.york.ac.uk

This code is made freely available, without warranty. It relies on the existence of a Fedora4 repository and solr instance containing data structured according the models here and in the accompanying arch1 application codebase: https://github.com/digital-york/arch1

For further information on the underlying data model, please see this (google document)[https://docs.google.com/document/d/1U3sLgaJr07d7LfvyDPT2rUnVAI1ccWp-Zeon_rlBd6o/edit]

Please contact us if you would like to make use of the codebase: dlib-info@york.ac.uk


= Local development quick start ==

Note: This version has been tested Ruby 2.5.3 and Rails 5.0.1.

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
