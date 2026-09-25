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
RUN git clone https://github.com/rbenv/rbenv.git ~/.rbenv \
    && echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc \
    && echo 'eval "$(rbenv init -)"' >> ~/.bashrc \
    && git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build \
    && ~/.rbenv/bin/rbenv install 2.7.3 \
    && ~/.rbenv/bin/rbenv global 2.7.3

# Set up rbenv environment
ENV PATH /root/.rbenv/shims:/root/.rbenv/bin:$PATH

# Verify installation
RUN ruby -v

# Set the working directory
WORKDIR /app

# Copy the current directory contents into the container at /app
COPY . /app

# Install any needed gems specified in Gemfile
RUN bundle install

# Make port 4567 available to the world outside this container
#EXPOSE 4567

# Run app.py when the container launches
#CMD ["ruby", "app.rb"]
