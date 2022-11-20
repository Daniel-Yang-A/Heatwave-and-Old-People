!apt update 
!apt install chromium-chromedriver 
!pip install selenium 
from selenium.webdriver.support.select import Select
from selenium import webdriver
from selenium.webdriver.common.by import By
import time
import pandas as pd
import numpy as np
import multiprocessing

# Note that the output csv file does not have a header
url0 = "https://wrcc.dri.edu/cgi-bin/wea_monsum.pl?ca"
code_df = pd.read_excel("NCA.xlsx")
codes = code_df['code']
location_names = code_df["name"]

# This is the actual header for the file
col_names = ["Location", "Year", "Month", "Day of Year", "Air Temperature max", "Humidity min"]

'''Browser settings'''
options = webdriver.ChromeOptions()
options.add_argument("--disable-blink-features=AutomationControlled")
options.add_argument('--ignore-certificate-errors-spki-list')
options.add_argument('--ignore-ssl-errors')
options.add_experimental_option('excludeSwitches', ['enable-logging'])
options.add_experimental_option("prefs", {"profile.managed_default_content_settings.images": 2}) 
options.add_argument("--no-sandbox") 
options.add_argument("--disable-setuid-sandbox")      

options.add_argument("--disable-extensions") 
options.add_argument('--headless')
options.add_argument("--disable-gpu") 
options.add_argument("start-maximized") 
options.add_argument("disable-infobars")
options.add_argument(r"user-data-dir=.\cookies\\test") 
options.add_experimental_option("detach", True)

def process(Years=['2013'], start=0, end=10):
    '''
    To crawl the data from the WRCC website

    Parameters
    ----------
    Years: list of shape ["xxxx", "xxxx", ...]
        the list of the stings of target years
    start: int
        the starting index of the code of weather stations
    end: int
        the ending index of the code of weather stations

    Returns
    ----------
    The function will generate a csv file whose name is in the 
    form of "year1_year2_...yearn_startInd_endInd.csv".

    Note
    ----------
    The generated file does not contain a header, while we
    need to add a header for it manually. The header should 
    be ["Location", "Year", "Month", "Day of Year", 
        "Air Temperature max", "Humidity min"]
    '''
    df_data = pd.DataFrame()
    file_name = "_".join(Years) + "_" + str(start) + "_" + str(end) + ".csv"


    Months = list(range(12))
    target_td_col_index = [1,9,18]         # This decides the column data we try to collect. We need to check it in the source page.
    count = 0
    total = (end-start) * 12 * len(Years)


    driver = webdriver.Chrome(options=options)
    for code_ind in range(start,end):
      for year in Years:
          for month in Months:
              count += 1
              if count % 12 == 0:
                print("For", "_".join(Years) + "_" + str(start) + "to" + str(end) + ":", count, "/", total, "=", count/total)
                df_data.to_csv(file_name,index=False, header=0, mode='a')
                df_data = pd.DataFrame()
              try:
                  code = codes[code_ind]
                  location = location_names[code_ind]

                  url = url0 + code
                  '''Launch the browser'''
                  
                  driver.get(url)

                  time.sleep(0.5)

                  driver.maximize_window()

                  '''Locate the selection bar of Month'''
                  # text_label = driver.find_element_by_xpath('//*[@name = "query" and @class="searchBox"]')
                  month_selection = driver.find_element(By.CSS_SELECTOR, "body>form>select[name='mon']")
                  Select(month_selection).select_by_index(month)

                  '''Locate the selection bar of Year'''
                  # text_label = driver.find_element_by_xpath('//*[@name = "query" and @class="searchBox"]')
                  year_selection = driver.find_element(By.CSS_SELECTOR, "body>form>select[name='yea']")
                  Select(year_selection).select_by_visible_text(str(year))

                  '''Locate the submit button and click'''
                  submit_button = driver.find_element(by='xpath', value='//body/form/input[@type="submit"]') 
                  submit_button.click()
                  time.sleep(0.4)
                  
                  driver.switch_to.window(driver.window_handles[-1])

                  time.sleep(0.4)

                  # Find all the tr elements in the desired table
                  content_list = driver.find_elements(by='xpath', value='//body/center[3]/table[1]/tbody/tr[@align="RIGHT"]') 

                  if len(content_list) > 0:             # Which means that the time info is available in the database
                      content_list = content_list[:-4]    
                      if len(content_list) not in [28,29,30,31]:
                          print(year, f": The number of month {month} is suspicious.")

                      page_data = []
                      for tr_row in content_list:
                          cells = tr_row.find_elements(by="xpath", value="./td")
                          desired_row_data = []
                          for ind in target_td_col_index:
                              desired_row_data.append(cells[ind].text)
                          desired_row_data = [location, year, month+1] + desired_row_data
                          page_data.append(desired_row_data)
                  else:
                      page_data = [[location, year, month+1]+[" "]*len(target_td_col_index)]

                  page_data = pd.DataFrame(page_data)
                  page_data.columns = col_names
                  df_data = pd.concat([df_data, page_data])
              except Exception as e:
                  page_data = [[location, year, month+1]+[" "]*len(target_td_col_index)]
                  page_data = pd.DataFrame(page_data)
                  page_data.columns = col_names
                  df_data = pd.concat([df_data, page_data])
                  print("Error happens for", code, year, month+1, e)

    df_data.to_csv(file_name,index=False, header=0, mode='a')


def main():
    process(["2013"],0,185)

if __name__ == '__main__':
    s = time.time()
    main()
    e = time.time()
    print('Time cost:',e-s)