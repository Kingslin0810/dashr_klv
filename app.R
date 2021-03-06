library(dash)
library(dashHtmlComponents)
library(ggplot2)
library(plotly)
library(purrr)
library(dplyr)
library(readr)
library(stringr)

#' Get COVID-19 data as data frame
#'
#' Retrieve covid data in pandas dataframe format witg tge time periods provided
#'
#' @return data.frame
#' @export
#'
#' @examples
#' get_data()
get_data <- function() {
    url <- "https://covid.ourworldindata.org/data/owid-covid-data.csv"
    
    tryCatch(
        {
            df <- read_csv(url)
        },
        error = function(e) {
            stop("The link to the data is broken.")
        }
    )
    
    columns <- c(
        "iso_code",
        "continent",
        "location",
        "date",
        "total_cases",
        "new_cases",
        "total_deaths",
        "new_deaths",
        "total_cases_per_million",
        "new_cases_per_million",
        "total_deaths_per_million",
        "new_deaths_per_million",
        "icu_patients",
        "icu_patients_per_million",
        "hosp_patients",
        "hosp_patients_per_million",
        "weekly_icu_admissions",
        "weekly_icu_admissions_per_million",
        "weekly_hosp_admissions",
        "weekly_hosp_admissions_per_million",
        "total_vaccinations",
        "people_vaccinated",
        "people_fully_vaccinated",
        "new_vaccinations",
        "population"
    )
    
    df <- df %>% select(all_of(columns))
    df <- filter(df, !str_detect(iso_code, "^OWID"))
    df <- df %>% replace(is.na(.), 0)
    
}

#' Get COVID-19 data as data frame
#'
#' Retrieve covid data in pandas dataframe format witg tge time periods provided
#'
#' @param date_from Start date of the data range with format like '2021-10-31'.
#' @param date_to End date of data range with format like '2021-10-31'.
#' @param countries Charactor vector of target country names. By default it retrieves all countries
#'
#' @return data.frame
#' @export
#'
#' @examples
#' get_data(date_from = "2022-01-01", date_to = "2022-01-07", location = c("Canada", "United State"))
filter_data <- function(df, date_from, date_to, countries) {
    if (missing(date_from)) {
        date_from <- df$date %>% min()
    }
    
    if (missing(date_to)) {
        date_to <- df$date %>% max()
    }
    
    df <- df %>%
        filter(date >= date_from, date <= date_to)
    
    if (!missing(countries)) {
        df <- df %>%
            filter(location %in% countries)
    }
    
    df
}

df <- get_data()

# Feature dropdown functions
feature_labels <- c("Total confirmed cases",
                    "Total confirmed cases per million people",
                    "Daily confirmed cases",
                    "Daily confirmed cases per million people",
                    "Total deaths",
                    "Total deaths per million people",
                    "Daily deaths",
                    "Daily deaths per million people"
)

feature_values <- c("total_cases",
                    "total_cases_per_million",
                    "new_cases",
                    "new_cases_per_million",
                    "total_deaths",
                    "total_deaths_per_million",
                    "new_deaths",
                    "new_deaths_per_million"
)

feature_mapping <- function(label, value) {
    list(label = label, value = value)
}

data_type_labels <- c("Linear", "Log")

data_type_values <- c("identity", "log")

data_type_mapping <- function(label, value) {
    list(label = label, value = value)
}

# feature dropdown
feature_dropdown = dccDropdown(
    id = "feature-dropdown",
    value = "total_cases_per_million",
    options = purrr::map2(feature_labels, feature_values, feature_mapping)
    
)

# feature dropdown2
feature_dropdown2 = dccDropdown(
    id = "feature-dropdown2",
    value = "total_cases_per_million",
    options = purrr::map2(feature_labels, feature_values, feature_mapping)
)

# feature dropdown3
feature_dropdown3 = dccDropdown(
    id = "feature-dropdown3",
    value = "total_cases_per_million",
    options = purrr::map2(feature_labels, feature_values, feature_mapping)
)


# Country selector
country <- df["location"] %>% unique() %>%
    unlist(use.names = FALSE)

country_selector <- dccDropdown(
    id = "country-selector",
    multi = TRUE,
    options = country %>% purrr::map(function(col) list(label = col, value = col)),
    value=c("Canada", "United States", "United Kingdom", "France", "Singapore"),
)

#Linear/Log Selector
scale_line_radio = dbcRadioItems(
    id = "scale-line-radio",
    options = purrr::map2(data_type_labels, data_type_values, data_type_mapping),
    value="identity",
)

#Linear/Log Selector
scale_line_radio2 = dbcRadioItems(
    id = "scale-line-radio2",
    options = purrr::map2(data_type_labels, data_type_values, data_type_mapping),
    value="identity",
)

# Tabs and sidebars
sidebar <- dbcCol(dbcRow(
    list(
        htmlBr(),
        htmlP(" "),
        htmlP(" "),
        htmlH3(
            "World COVID-19 Dashboard", style = list("font" = "Helvetica", "font-size" = "25px", "text-align" = "center")
        ),
        htmlP(" "),
        htmlP(" "),
        htmlBr(),
        htmlBr(),
        htmlP(
            "Explore the global situation of COVID-19 using this interactive dashboard. Compare selected countries and indicators across different date ranges to observe the effect of policy, and vaccination rate.",
            style = list("text-align" = "justify")),    
        htmlHr(),
        htmlBr(),
        htmlBr(),
        htmlB("Country Filter"),
        htmlP(
            "Use this filter to add or remove a country from the analysis",
        ),
        htmlBr(),
        htmlBr(),      
        country_selector
    )
),
width = 2,
style = list(
    "border-width" = "0",
    "backgroundColor" = "#d3e9ff"
),
)

# map tab
map_tab <- dbcRow(
    list(
        htmlP(" "),
        htmlP(
            "World Map",
            style = list("font-size" = "25px"),
        ),
        htmlP(
            "The map below depicts the selected COVID-19 indicator for the selected countries. Use the play button to animate the timeline of this indicator over the date range selected by the slider above.",
        ),
        htmlB("Indicator:"),
        htmlP(
            "Select an indicator to explore on the map and line plot using the dropdown below.",
        ),
        htmlBr(),
        htmlBr(),
        feature_dropdown,
        dccLoading(
            dccGraph(
                id = "map-plot",
                style = list("height" = "70vh"),
            )
        )
    )
)

# Line tab
line_tab <- dbcRow(
    list(
        htmlP(" "),
        htmlP(
            "Line Plot",
            style = list("font-size" = "25px"),
        ),
        htmlP(
            "The line plot below depicts the selected COVID-19 indicator for the selected countries. Click the legend to highlight particular countries.",
        ),
        htmlB("Indicator:"),
        htmlP(
            "Select an indicator to explore on the map and line plot using the dropdown below.",
        ),
        htmlBr(),
        htmlBr(),
        feature_dropdown2,
        htmlP(
            " ",
        ),
        dbcCol(
            list(htmlP(" ",),
                 htmlB("Data Scale"),
                 scale_line_radio),
            width = 1,
        ),
        dbcCol(
            dccLoading(
                dccGraph(
                    id = "line-plot",
                    style = list("height" = "70vh"),
                )
            )
        )
    )
)


# Charts tab
chart_tab <- dbcRow(
    list(
        htmlP(" "),
        htmlP(
            "Line Plot - Current ICU Hospitalizations",
            style = list("font-size" = "25px"),
        ),
        htmlP(
            "Shows the current number of people per million admitted to the ICU for the selected countries, over the date range selected by the slider above.",
        ),
        htmlBr(),
        htmlP(
            " ",
        ),
        dbcCol(
            list(htmlP(" ",),
                 htmlB("Data Scale"),
                 scale_line_radio2),
            width = 1,
        ),
        dbcCol(
            dccLoading(
                dccGraph(
                    id = "line_plot2",
                    style = list("height" = "70vh"),
                )
            )
        )
    )
)


# APP codes
app <- Dash$new(external_stylesheets = dbcThemes$FLATLY)

app$layout(
    dbcContainer(
        dbcRow(
            list(
                sidebar,
                dbcCol(
                    list(
                        dbcRow(
                            list(
                                htmlP(" "),
                                htmlB("date_display"),
                                htmlBr(),
                                htmlBr(),
                                htmlP(" "),
                                htmlB("date_slider"),
                                htmlBr(),
                                htmlBr(),
                                htmlP(" "),
                                dbcTabs(
                                    list(
                                        dbcTab(
                                            map_tab,
                                            label = "Global COVID-19 Map",
                                            tab_id="map-tab"
                                        ),
                                        dbcTab(
                                            line_tab,
                                            label="Global COVID-19 Plot",
                                            tab_id="line-tab"
                                        ),
                                        dbcTab(
                                            chart_tab,
                                            label="Vaccination and Hospitalization Indicators",
                                            tab_id="charts-tab"
                                        )
                                    )
                                )
                            )
                        )
                    ),
                    width = 10
                )
            )
        ),
        fluid=TRUE
    )
)

app$callback(
    output('line_plot2', 'figure'),
    list(
        # input('feature-dropdown3', 'value'),
         input('country-selector', 'value'),
         input('scale-line-radio', 'value')),
    function(countries, scale_type) {
        # max_date <- df$date %>% max()
        filter_df <- filter_data(df, 
                                 # date_from = max_date, 
                                 countries=countries)
        
        
        # filter_df$hover <- with(filter_df, paste(" Date:", date, '<br>',
        #                                          "Location: ", location, '<br>' 
        # ))
        # # map_plot
        # map_plot <- plot_geo(filter_df)
        # 
        # map_plot <- map_plot %>%
        #     add_trace(
        #         z = as.formula(paste0("~`", xcol, "`")), text = ~hover, 
        #         locations = ~iso_code,
        #         color = as.formula(paste0("~`", xcol, "`")), colors = 'Purples'
        #     )
        # 
        # map_plot <- map_plot %>% colorbar(title = "Count")  %>% 
        #     ggplotly(map_plot)
        
        #line plot1
        # line_plot1 <- ggplot(filter_df,
        #                     aes(x = date,
        #                         y = !!sym(ycol),
        #                         color = location)) +
        #     geom_line(stat = 'summary', fun = mean) +
        #     ggtitle(paste0("Country data for ", ycol)) +
        #     scale_y_continuous(trans = scale_type)
        # 
        # line_plot1 <- line_plot1 %>%
        #     ggplotly()
        # 
        #line plot2
        #ycol<- "icu_patients_per_million"
        line_plot2 <- ggplot(filter_df,
                             aes(x = date,
                                 y = icu_patients_per_million,
                            color = location)) +
            geom_line(stat = 'summary', fun = mean) 
            #ggtitle(paste0("Country data for ", ycol)) 
            #scale_y_continuous(trans = scale_type)

        
        line_plot2 <- line_plot2 %>%
            ggplotly()        
    }
)

app$run_server(host = "0.0.0.0")