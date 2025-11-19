import { useState } from 'react';
import PropTypes from 'prop-types';

function DatabaseTabs({ children, defaultDatabase }) {
  const [activeTab, setActiveTab] = useState(defaultDatabase);

  // Convert children to array and filter valid tabs
  const tabs = Array.isArray(children) ? children : [children];
  const validTabs = tabs.filter((child) => child && child.props);

  if (validTabs.length === 0) {
    return null;
  }

  const activeContent = validTabs.find((tab) => tab.props.database === activeTab);

  return (
    <div className="database-tabs mb-4">
      <ul className="nav nav-tabs" role="tablist">
        {validTabs.map((tab) => {
          const { database, label, icon } = tab.props;
          return (
            <li className="nav-item" role="presentation" key={database}>
              <button
                type="button"
                className={`nav-link ${activeTab === database ? 'active' : ''}`}
                onClick={() => setActiveTab(database)}
                role="tab"
                aria-selected={activeTab === database}
                aria-controls={`${database}-tab`}
              >
                {icon && <i className={`bi ${icon} me-2`} />}
                {label}
              </button>
            </li>
          );
        })}
      </ul>
      <div className="tab-content border border-top-0 rounded-bottom p-3 bg-light">
        <div
          className="tab-pane fade show active"
          role="tabpanel"
          id={`${activeTab}-tab`}
        >
          {activeContent}
        </div>
      </div>
    </div>
  );
}

DatabaseTabs.propTypes = {
  children: PropTypes.node.isRequired,
  defaultDatabase: PropTypes.string,
};

DatabaseTabs.defaultProps = {
  defaultDatabase: 'postgresql',
};

function Tab({ children, database, label, icon }) {
  return <div data-database={database} data-label={label} data-icon={icon}>{children}</div>;
}

Tab.propTypes = {
  children: PropTypes.node.isRequired,
  database: PropTypes.string.isRequired,
  label: PropTypes.string.isRequired,
  icon: PropTypes.string,
};

Tab.defaultProps = {
  icon: null,
};

DatabaseTabs.Tab = Tab;

export default DatabaseTabs;
export { Tab };
