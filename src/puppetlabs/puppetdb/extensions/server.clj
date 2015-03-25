(ns puppetlabs.puppetdb.extensions.server
  (:require [compojure.core]
            [puppetlabs.puppetdb.extensions.state-overview :as state-overview]
            [puppetlabs.puppetdb.middleware :refer
             [wrap-with-puppetdb-middleware wrap-with-globals]]
            [clojure.tools.logging :as log]
            [puppetlabs.trapperkeeper.core :refer [defservice]]
            [compojure.core :refer [GET ANY routes] :as compojure]))

(def v1-app
  (routes (GET "/state-overview" [] state-overview/state-overview-app)))

(defn build-app
  "Generate a Ring application that handles PuppetDB requests

  `globals` is a map containing global state useful
   to request handlers which may contain the following:

  * `authorizer` - a function that takes a request and returns a
    :authorized if the request is authorized, or a user-visible reason if not.
    If not supplied, we default to authorizing all requests."
  [{:keys [authorizer] :as globals}]
  (-> (routes (compojure/context "/v1" [] v1-app))
      (wrap-with-puppetdb-middleware authorizer)
      (wrap-with-globals globals)))

(defservice pe-puppetdb-service
  [[:PuppetDBServer shared-globals]
   [:WebroutingService add-ring-handler get-route]]

  (start [this context]
         (let [app (->> (build-app (shared-globals))
                        (compojure/context (get-route this) []))]
           (log/info "Starting pe-puppetdb server")
           (add-ring-handler this app)
           context)))
