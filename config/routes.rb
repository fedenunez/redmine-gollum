resources :projects do
#/projects/remoto/gollum/diagrams/architecture_overview.png
  match 'gollum/:id/edit', :controller => 'gollum', :action => 'edit', :id => /.*[a-zA-Z0-9]+/, :via => :get
  match 'gollum/:id', :controller => 'gollum', :action => 'show', :id => /.*[a-zA-Z0-9]+/, :via => :get
  resource  :gollum_wiki
  resources :gollum
end
