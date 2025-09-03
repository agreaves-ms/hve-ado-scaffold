# GitHub Copilot for Data Science

## Copilot Chat Modes (.github/chatmodes) for workflow automation

Located in [`.github/chatmodes/`](./.github/chatmodes/). Specialized persistent personas for data science workflows:

* [`gen-data-spec.chatmode.md`](./.github/chatmodes/gen-data-spec.chatmode.md) - Systematic data discovery and content review. Analyzes directory structures, previews data formats, and creates exploration plans in `docs/notes/`.
* [`uv-env.chatmode.md`](./.github/chatmodes/uv-env.chatmode.md) - Python environment specialist using uv for virtual environment management. Handles project initialization, dependency management, and CUDA detection for ML workflows.
* [`gen-jupyter-notebook.chatmode.md`](./.github/chatmodes/gen-jupyter-notebook.chatmode.md) - Exploratory data analysis notebook creation. Generates comprehensive EDA notebooks with summary statistics, visualizations, and data transforms using pandas, seaborn, and plotly.
* [`gen-streamlit-dashboard.chatmode.md`](./.github/chatmodes/gen-streamlit-dashboard.chatmode.md) - Multi-page Streamlit dashboard development. Creates interactive data exploration apps with univariate/multivariate analysis, time series visualization, and optional AutoGen chat integration.
* [`test-streamlit-dashboard.chatmode.md`](./.github/chatmodes/test-streamlit-dashboard.chatmode.md) - Automated functional and behavioral testing for Streamlit dashboards. Uses Playwright and the VS Code Simple Browser extension to interact with the app, validate UI flows, and ensure dashboard reliability.

Why chat modes? They reduce drift: each mode enforces domain‑specific rigor and artifacts. For data science, they create a structured workflow from data discovery → environment setup → exploration → dashboard deployment.

## Labs

These hands-on labs demonstrate the complete data science workflow using GitHub Copilot chatmodes, from environment setup through interactive dashboard deployment and testing.

### Lab 0: Python Environment Setup with uv

#### Objective

Establish a reproducible Python development environment using uv for modern dependency management, optimized for data science workflows.

#### Steps

1. **Activate the uv Environment Chatmode**
   * Open GitHub Copilot Chat in VS Code
   * Type: `@workspace #file:chatmodes use the uv-env chatmode to set up a Python 3.11 environment for data science`

2. **Initialize the Project**
   * Copilot will execute: `uv init` to create project structure
   * Automatically generates `pyproject.toml` with project metadata
   * Creates `.venv` virtual environment directory

3. **Install Core Data Science Dependencies**
   * Copilot automatically adds essential packages:
     * `ipykernel` and `ipywidgets` for Jupyter notebook support
     * `black` for code formatting
     * `tqdm` for progress bars
     * `pytest` for testing
   * Additional packages will be added based on your data requirements

4. **Environment Activation and Validation**
   * Copilot will guide you through activation: `source .venv/bin/activate`
   * Verify installation with: `uv pip freeze` and examine the `pyproject.toml`
   * Test Jupyter kernel registration for VS Code notebook support

#### Expected Outcomes

* Clean `pyproject.toml` with properly configured dependencies
* Activated virtual environment with core data science tools
* Ready-to-use development environment for subsequent labs

#### Tips

* The uv chatmode automatically handles CUDA detection for PyTorch installations
* All dependency changes are tracked in `pyproject.toml` and `uv.lock`
* Use `uv add <package>` for additional dependencies throughout the workflow

### Lab 1: Data Discovery and Specification

#### Objective

Use GitHub Copilot to automatically generate comprehensive data specifications and documentation from your raw datasets, creating the foundation for all downstream analysis.

#### Prerequisites

* Completed Lab 0 (environment setup)
* Raw data files in a `data/` directory
* Access to `gen-data-spec.chatmode.md`

#### Steps

1. **Prepare Your Data Directory**
   * Place your datasets (CSV, Excel, Parquet, JSON, etc.) in `data/`
   * For this example, ensure `data/home_assistant_data.csv` is available
   * Organize any supplementary data files or documentation

2. **Activate the Data Specification Chatmode**
   * Open Copilot Chat and reference: `@workspace #file:chatmodes use the gen-data-spec chatmode to analyze my data directory`
   * Point Copilot to your specific data path: `analyze the data in ./data/`

3. **Automated Data Discovery**
   * Copilot will:
     * Scan your data directory structure
     * Preview file formats and schemas
     * Detect column types, ranges, and patterns
     * Identify potential relationships between datasets
     * Generate sample records for context

4. **Specification Generation**
   * Copilot creates comprehensive artifacts in `outputs/`:
     * `data-dictionary-<dataset>-<date>.md`: Variable definitions and metadata
     * `data-summary-<dataset>-<date>.md`: Statistical summaries and quality assessments
     * `data-profile-<dataset>-<date>.json`: Structured data profiling results
     * `data-objectives-<dataset>-<date>.json`: Suggested analysis objectives

5. **Review and Refinement**
   * Examine generated specifications for accuracy
   * Provide domain-specific context or corrections
   * Validate data quality assessments and range checks

#### Expected Outcomes

* Complete data dictionary with variable types, ranges, and business meanings
* Statistical profile highlighting data quality issues and patterns
* Structured objectives for exploratory data analysis
* Documentation artifacts that inform downstream analysis design

### Lab 2: Automated Jupyter Notebook Creation

#### Objective

Generate a comprehensive exploratory data analysis (EDA) notebook using GitHub Copilot, incorporating your data specification to create structured, publication-ready analysis.

#### Prerequisites

* Completed Labs 0-1 (environment and data specification)
* Data dictionary and profile artifacts in `outputs/`
* Access to `gen-jupyter notebook.chatmode.md`

#### Steps

1. **Activate the Jupyter Notebook Chatmode**
   * Reference the chatmode: `@workspace #file:chatmodes use the gen-jupyter notebook chatmode`
   * Specify your data context: `create a comprehensive EDA notebook for the home assistant dataset using the existing data specification`

2. **Automated Notebook Generation**
   * Copilot creates a structured notebook in `notebooks/` with these sections:
     * **Title & Overview**: Dataset summary and analysis objectives
     * **Data Assets Summary**: References to specifications without data duplication
     * **Configuration & Imports**: Parameterized paths and required libraries
     * **Data Loading**: Safe, sampling-aware data ingestion
     * **Data Quality Checks**: Shape, types, and missingness validation
     * **Univariate Analysis**: Distributions, outliers, and statistical summaries
     * **Multivariate Analysis**: Correlations, relationships, and interactions
     * **Time Series Analysis**: Temporal patterns and trends (if applicable)
     * **Feature Engineering**: Derived variables and transformations
     * **Summary Insights**: Key findings and analytical recommendations

3. **Visualization Strategy**
   * Primary visualization library: **Plotly Express** for interactivity
   * Fallback to Seaborn/Matplotlib for specialized statistical plots
   * Consistent theming and semantic variable naming
   * Responsive design with appropriate sampling for large datasets

4. **Data Processing Pipeline**
   * Automated artifact creation in `data/processed/` with semantic naming
   * Version-controlled processed datasets using `.parquet` format
   * Metadata registry tracking all generated artifacts
   * Reproducible data transformations with clear lineage

5. **Dependency Management Integration**
   * Copilot automatically identifies required packages from notebook imports
   * Executes `uv add <packages>` to update `pyproject.toml`
   * Ensures environment consistency across team members

#### Expected Outcomes

* **Executable Notebook**: Runs end-to-end without manual intervention
* **Rich Visualizations**: Interactive plots addressing key analytical questions
* **Processed Artifacts**: Curated datasets ready for dashboard deployment
* **Documentation**: Interpretive markdown with insights and next steps
* **Reproducibility**: Parameterized paths and versioned dependencies

### Lab 3: Interactive Streamlit Dashboard Development

#### Objective

Transform your EDA insights into a production-ready, multi-page Streamlit dashboard with interactive visualizations and automated testing capabilities.

#### Prerequisites

* Completed Labs 0-2 (environment, specification, notebook)
* EDA notebook with processed datasets
* Access to `gen-streamlit-dashboard.chatmode.md`

#### Steps

1. **Activate the Streamlit Dashboard Chatmode**
   * Reference: `@workspace #file:chatmodes use the gen-streamlit-dashboard chatmode`
   * Context: `create a comprehensive dashboard based on my EDA notebook and data specifications`

2. **Multi-Page Dashboard Architecture**
   * Copilot generates a structured app with these components:
     * `app.py`: Main application entry point with navigation
     * `src/pages/summary.py`: Summary statistics and data overview
     * `src/pages/univariate.py`: Single-variable distribution analysis
     * `src/pages/multivariate.py`: Correlation analysis and relationships
     * `src/pages/timeseries.py`: Temporal pattern visualization
     * `src/pages/chat.py`: Optional AutoGen-powered conversational interface
     * `src/utils.py`: Shared utilities and data loading functions

### Lab 4: Automated Dashboard Testing

#### Objective

Implement comprehensive automated testing for your Streamlit dashboard using Playwright automation, ensuring reliability and user experience quality.

#### Prerequisites

* Completed Labs 0-3 (environment, specification, notebook, dashboard)
* Running Streamlit application
* Access to `test-streamlit-dashboard.chatmode.md`

#### Steps

1. **Activate the Testing Chatmode**
   * Reference: `@workspace #file:chatmodes use the test-streamlit-dashboard chatmode`
   * Context: `create comprehensive Playwright tests for my home assistant dashboard`

2. **Test Environment Setup**
   * Copilot automatically installs testing dependencies:

     ```bash
     uv add playwright pytest-playwright pytest-asyncio
     ```

   * Configures Playwright browsers: `playwright install`
   * Sets up test directory structure in `tests/`

3. **Comprehensive Testing Strategy**

   **Phase 1: Functional Testing**
   * Navigation between all dashboard pages
   * Interactive element responses (dropdowns, sliders, buttons)
   * Data loading validation across pages
   * Visualization rendering verification
   * Error handling with invalid inputs

   **Phase 2: Data Integrity Testing**
   * Validate displayed statistics match expected values from data specification
   * Test handling of missing data and edge cases
   * Verify temporal data consistency and ordering
   * Check correlation calculations and statistical accuracy

   **Phase 3: User Experience Testing**
   * Responsive design across viewport sizes
   * Loading state visibility and duration
   * Error message clarity and helpfulness
   * Accessibility features and keyboard navigation

   **Phase 4: Performance Testing**
   * Page load time measurements
   * Memory usage monitoring during extended sessions
   * Caching behavior validation
   * Concurrent user simulation

4. **Automated Test Execution**

   **Sample Test Structure**:

   ```python
   async def test_summary_page_metrics(page):
       """Verify summary statistics display correctly"""
       await page.goto("http://localhost:8501")

       # Navigate to summary page
       await page.select_option("[data-testid='stSidebar'] select", "📊 Summary Statistics")

       # Verify key metrics are displayed
       total_records = await page.locator("[data-testid='metric-value']").first.text_content()
       assert "100,002" in total_records

       # Check data quality section
       quality_section = page.locator("text=Data Quality Overview")
       await expect(quality_section).to_be_visible()
   ```

5. **Issue Tracking and Reporting**
   * Automated generation of structured test reports
   * Issue classification by severity and category
   * Performance benchmarking and trend analysis
   * Actionable recommendations for improvements

#### Expected Outcomes

* **Automated Test Suite**: Comprehensive coverage of all dashboard functionality
* **Continuous Quality Assurance**: Repeatable testing for regression detection
* **Performance Baselines**: Established metrics for monitoring application health
* **Issue Documentation**: Systematic tracking of bugs and enhancement opportunities

#### Test Execution Workflow

1. **Pre-Test Setup**

   ```bash
   # Start dashboard in background
   streamlit run app.py --server.port 8501 &

   # Wait for application startup
   sleep 5
   ```

2. **Run Test Suite**

   ```bash
   # Execute all tests
   pytest tests/ --browser=chromium --headed

   # Generate HTML report
   pytest tests/ --html=reports/test-results.html
   ```

3. **Results Analysis**
   * Review test results and failure details
   * Analyze performance metrics and trends
   * Prioritize issues based on user impact
   * Create action items for bug fixes and enhancements

#### Integration with Development Workflow

* **Continuous Testing**: Run tests automatically on code changes
* **Performance Monitoring**: Track metrics over time for regression detection
* **Quality Gates**: Establish pass/fail criteria for deployment
* **Documentation**: Maintain test coverage and known limitation records

---

### Lab Integration and Workflow

The four labs work together to create a complete data science development lifecycle:

**Lab 0 → Lab 1**: Environment setup enables reliable data discovery and specification generation

**Lab 1 → Lab 2**: Data specifications inform structured EDA notebook creation with relevant analyses

**Lab 2 → Lab 3**: EDA insights and processed datasets drive interactive dashboard development

**Lab 3 → Lab 4**: Completed dashboard undergoes comprehensive testing for production readiness

Each lab leverages specialized GitHub Copilot chatmodes that enforce domain-specific best practices while maintaining workflow continuity. The result is a reproducible, tested, and documented data science project suitable for both exploration and production deployment.
