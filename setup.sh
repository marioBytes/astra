#!/bin/bash

# create database, migrate files, and generate data
mix ecto.create

mix ecto.migrate

mix run priv/repo/seeds.exs
