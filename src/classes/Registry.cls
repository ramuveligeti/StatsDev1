public class Registry {
    private static Registry instance;
    private Map<Type, Object> m = new Map<Type, Object>();
    // Set a view state field to this
    public static Registry instance() {
        if (instance == null) instance = new Registry();
        return instance;
    }
    // Singleton
    private Registry() {
    }
    public void add(Type key, Object value) {
        m.put(key, value);
    }
    public Object get(Type key) {
        return m.get(key);
    }
}