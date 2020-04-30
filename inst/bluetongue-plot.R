library(repeldata)
library(tidyverse)
library(stringi)
library(lubridate)
library(ggridges)

outbreaks <- collect(tbl(repel_remote_conn(), "outbreak_reports_events"))

threads <- outbreaks %>% 
    select(id, immediate_report, report_type, disease, country,date_of_start_of_the_event, date_event_resolved, reason_for_notification) %>% 
    arrange(immediate_report, report_type)

outbreak_reports_outbreaks <- collect(tbl(repel_remote_conn(), "outbreak_reports_outbreaks"))
outbreak_reports_outbreaks %>% count(outbreak_status)
threads2 <- threads %>% 
    group_by(immediate_report, country, disease) %>% 
    summarize(start = min(date_of_start_of_the_event),
              end = if_else(
                  all(is.na(date_event_resolved)), as.Date(NA),
                  max(date_event_resolved, na.rm = TRUE)),
              reason = reason_for_notification[1]) %>% 
    arrange(start, country, disease) %>% 
    mutate(days = interval(start, end) / ddays(1))

segs <- threads2 %>% 
    filter(disease == "ovine bluetongue disease", !is.na(days)) %>% 
    arrange(country, start) %>% 
    group_by(country) %>% 
    mutate(tot_days = sum(days, na.rm = TRUE)) %>% 
    group_by() %>% 
    mutate(country = fct_reorder(country, tot_days)) %>% 
    group_by(country) %>% 
    mutate(n_in_country = n()) %>% 
    group_by() %>% 
    mutate(ypos = as.integer(country) + if_else(n_in_country > 1, runif(n(), -0.4, 0.4), 0))
ggplot(segs, aes(x=start, y=country)) +
    geom_segment(mapping=aes(y = ypos, yend = ypos, x = start, xend = end)) +
    scale_y_continuous(breaks = 1:nlevels(segs$country), labels = levels(segs$country)) +
    theme_bw()
