FROM ubuntu:24.04

# Install dependencies
RUN apt-get update -qq && apt-get upgrade -y \
    && apt-get install -y software-properties-common \
    && add-apt-repository universe \
    && apt-get update -qq && apt-get install -y \
    git \
    curl \
    autoconf \
    bison \
    build-essential \
    libssl-dev \
    libyaml-dev \
    libreadline-dev \
    zlib1g-dev \
    libncurses5-dev \
    libffi-dev \
    libgdbm6 \
    libgdbm-dev \
    libsqlite3-dev \
    nodejs 

# Install rbenv and ruby-build
# RUN git clone https://github.com/rbenv/rbenv.git ~/.rbenv \
#     && echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc \
#     && echo 'eval "$(rbenv init -)"' >> ~/.bashrc \
#     && git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build \
#     && ~/.rbenv/bin/rbenv install 2.7.3 \
#     && ~/.rbenv/bin/rbenv global 2.7.3

RUN git clone https://github.com/rbenv/rbenv.git ~/.rbenv \
    && echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc \
    && echo 'eval "$(rbenv init -)"' >> ~/.bashrc \
    && git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build \
    && ~/.rbenv/bin/rbenv install 2.7.3 || true \
    && ~/.rbenv/bin/rbenv global 2.7.3

# RUN git clone https://github.com/rbenv/rbenv.git ~/.rbenv \
#     && echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc \
#     && echo 'eval "$(rbenv init -)"' >> ~/.bashrc \
#     && git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build \
#     && ~/.rbenv/bin/rbenv install 3.1.0 \
#     && ~/.rbenv/bin/rbenv global 3.1.0

# Set up rbenv environment
ENV PATH /root/.rbenv/shims:/root/.rbenv/bin:$PATH

# Verify installation
RUN ruby -v

# Set the working directory
# WORKDIR /app

# Copy the current directory contents into the container at /app
# COPY . /app

# Install any needed gems specified in Gemfile
# RUN bundle install

# Install gems specified in Gemfile
# RUN gem install bundler -v 2.4.22 && bundle install

# Make port 4567 available to the world outside this container
#EXPOSE 4567

# Expose port 3000 for Rails
# EXPOSE 3000

# Run app.py when the container launches
# CMD ["ruby", "app.rb"]

# Command to start the Rails server
# CMD ["rails", "server", "-b", "0.0.0.0"]

# Start Solr, Fedora, and Rails server
# CMD ["bash", "-c", "bundle exec solr_wrapper & bundle exec fcrepo_wrapper & bundle exec rails s -b 0.0.0.0"]
# CMD ["bash", "-c", "bundle exec solr_wrapper & bundle exec fcrepo_wrapper"]